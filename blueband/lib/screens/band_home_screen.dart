import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ble_packet.dart';
import '../services/biometric_service.dart';
import '../services/ble_client_service.dart';
import '../services/student_identity_service.dart';
import '../widgets/fingerprint_button_widget.dart';
import '../widgets/led_indicator_widget.dart';
import '../widgets/packet_log_dialog.dart';
import 'identity_settings_dialog.dart';

class BandHomeScreen extends StatefulWidget {
  const BandHomeScreen({super.key});

  @override
  State<BandHomeScreen> createState() => _BandHomeScreenState();
}

class _BandHomeScreenState extends State<BandHomeScreen>
    with TickerProviderStateMixin {
  Timer? _tickerTimer;
  int _secondsAgo = 0;
  late AnimationController _bgPulseController;
  late AnimationController _connectBtnController;

  @override
  void initState() {
    super.initState();

    _bgPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _connectBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentIdentityService>(context, listen: false).loadIdentity();
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final bleClient =
          Provider.of<BleClientService>(context, listen: false);
      if (bleClient.lastSignalSentAt != null) {
        setState(() {
          _secondsAgo = DateTime.now()
              .difference(bleClient.lastSignalSentAt!)
              .inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _bgPulseController.dispose();
    _connectBtnController.dispose();
    super.dispose();
  }

  void _onVerificationChanged() {
    final identity =
        Provider.of<StudentIdentityService>(context, listen: false);
    final bioService = Provider.of<BiometricService>(context, listen: false);
    final bleClient = Provider.of<BleClientService>(context, listen: false);

    if (bleClient.status == BandConnectionStatus.connectedGreen) {
      bleClient.sendPacket(
        rollNumber: identity.rollNumber,
        studentName: identity.name,
        verified: bioService.isVerified,
        packetType: PacketType.heartbeat,
      );
    }
  }

  Future<void> _toggleConnection() async {
    HapticFeedback.mediumImpact();
    final identity =
        Provider.of<StudentIdentityService>(context, listen: false);
    final bioService = Provider.of<BiometricService>(context, listen: false);
    final bleClient = Provider.of<BleClientService>(context, listen: false);

    _connectBtnController.forward(from: 0);

    if (bleClient.status == BandConnectionStatus.connectedGreen) {
      await bleClient.disconnect();
    } else {
      await bleClient.connectToStaffHost(
        rollNumber: identity.rollNumber,
        studentName: identity.name,
        verified: bioService.isVerified,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = Provider.of<StudentIdentityService>(context);
    final bleClient = Provider.of<BleClientService>(context);
    final bioService = Provider.of<BiometricService>(context);

    final isConnected = bleClient.status == BandConnectionStatus.connectedGreen;
    final isConnecting =
        bleClient.status == BandConnectionStatus.connectingYellow;
    final isVerified = bioService.isVerified;

    // Accent colour cascades with state
    final Color accentColor = isConnected
        ? (isVerified
            ? const Color(0xFF00FF88)
            : const Color(0xFFFFCC00))
        : const Color(0xFF00C8FF);

    return Scaffold(
      backgroundColor: const Color(0xFF060A12),
      body: Stack(
        children: [
          // ─── Animated Background Gradient Orbs ────────────────────────
          AnimatedBuilder(
            animation: _bgPulseController,
            builder: (context, _) {
              final t = _bgPulseController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -80 + math.sin(t * 2 * math.pi) * 30,
                    left: -60,
                    child: _buildGlowOrb(
                      color: isConnected
                          ? accentColor.withValues(alpha: 0.12)
                          : const Color(0xFF003366).withValues(alpha: 0.3),
                      size: 300,
                    ),
                  ),
                  Positioned(
                    bottom: -100 + math.cos(t * 2 * math.pi) * 20,
                    right: -80,
                    child: _buildGlowOrb(
                      color: const Color(0xFF001833).withValues(alpha: 0.5),
                      size: 280,
                    ),
                  ),
                ],
              );
            },
          ),

          // ─── Main Content ──────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // ── App Bar Row ──
                    _buildTopBar(context, bleClient, identity),
                    const SizedBox(height: 20),

                    // ── Main Band Card ──
                    _buildBandCard(
                      context,
                      bleClient: bleClient,
                      bioService: bioService,
                      identity: identity,
                      isConnected: isConnected,
                      isConnecting: isConnecting,
                      isVerified: isVerified,
                      accentColor: accentColor,
                    ),

                    const SizedBox(height: 16),

                    // ── Session Telemetry Card ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isConnected
                          ? _buildSessionCard(bleClient, accentColor, isVerified)
                          : _buildOfflineHintCard(),
                    ),

                    const SizedBox(height: 16),

                    // ── Packet Log Button ──
                    _buildPacketLogButton(context, bleClient),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────── Widgets ──────────────────────────────

  Widget _buildGlowOrb({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    BleClientService bleClient,
    StudentIdentityService identity,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App brand
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C8FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.watch_rounded,
                  color: Color(0xFF00C8FF), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'BlueBand',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        // LED Status Indicator
        LedIndicatorWidget(status: bleClient.status),
      ],
    );
  }

  Widget _buildBandCard(
    BuildContext context, {
    required BleClientService bleClient,
    required BiometricService bioService,
    required StudentIdentityService identity,
    required bool isConnected,
    required bool isConnecting,
    required bool isVerified,
    required Color accentColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0E1826),
            const Color(0xFF0A1020),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: accentColor.withValues(alpha: isConnected ? 0.5 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isConnected ? 0.18 : 0.05),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Identity Badge ──
          _buildIdentityBadge(context, identity, accentColor),
          const SizedBox(height: 28),

          // ── Fingerprint Sensor ──
          FingerprintButtonWidget(
            onVerificationChanged: _onVerificationChanged,
          ),
          const SizedBox(height: 28),

          // ── Connect / Disconnect Button ──
          _buildConnectButton(isConnected, isConnecting, accentColor),
        ],
      ),
    );
  }

  Widget _buildIdentityBadge(
    BuildContext context,
    StudentIdentityService identity,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => const IdentitySettingsDialog(),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.8),
                    accentColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  identity.name.isNotEmpty
                      ? identity.name[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    identity.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${identity.rollNumber}',
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.grey, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton(
    bool isConnected,
    bool isConnecting,
    Color accentColor,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(
          parent: _connectBtnController,
          curve: Curves.easeInOut,
        ),
      ),
      child: GestureDetector(
        onTap: isConnecting ? null : _toggleConnection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: isConnected
                ? LinearGradient(
                    colors: [
                      Colors.red.shade900.withValues(alpha: 0.7),
                      Colors.red.shade800.withValues(alpha: 0.5),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.7),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.red : accentColor)
                    .withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isConnecting
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black.withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'PAIRING WITH HOST...',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  )
                : Text(
                    isConnected ? '⬛  DISCONNECT FROM HOST' : '⚡  CONNECT TO BLE HOST',
                    style: TextStyle(
                      color: isConnected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BleClientService bleClient,
    Color accentColor,
    bool isVerified,
  ) {
    return Container(
      key: const ValueKey('session_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_tethering_rounded,
                    color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bleClient.sessionHostName ?? 'BlueMesh Staff Host',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Active Session',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Verification badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isVerified
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFFCC00))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isVerified
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFFCC00),
                    width: 1,
                  ),
                ),
                child: Text(
                  isVerified ? '🟢 VERIFIED' : '🟡 PENDING',
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFFCC00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                label: 'Session Time',
                value: bleClient.formattedSessionTime,
                icon: Icons.timer_rounded,
                color: accentColor,
              ),
              _buildStatChip(
                label: 'Last Signal',
                value: '${_secondsAgo}s ago',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF00C8FF),
              ),
              _buildStatChip(
                label: 'Total Pings',
                value: '${bleClient.totalPingsSent}',
                icon: Icons.wifi_rounded,
                color: const Color(0xFFB47AFF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildOfflineHintCard() {
    return Container(
      key: const ValueKey('offline_card'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded,
              color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap "Connect" to pair with a BlueMesh Staff BLE Host and start attendance tracking.',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketLogButton(
      BuildContext context, BleClientService bleClient) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => PacketLogDialog(logs: bleClient.packetLogs),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF00C8FF).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00C8FF).withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_rounded,
                color: Color(0xFF00C8FF), size: 16),
            SizedBox(width: 8),
            Text(
              'Inspect BLE Telemetry Log',
              style: TextStyle(
                  color: Color(0xFF00C8FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

