import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../models/network_node.dart';
import '../../services/attendance_service.dart';
import '../../services/ble_host_service.dart';
import '../reports/session_report_screen.dart';

class NetworkVisualizerScreen extends StatefulWidget {
  final String sessionName;

  const NetworkVisualizerScreen({super.key, required this.sessionName});

  @override
  State<NetworkVisualizerScreen> createState() =>
      _NetworkVisualizerScreenState();
}

class _NetworkVisualizerScreenState extends State<NetworkVisualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TransformationController _transformController =
      TransformationController();
  NetworkNode? _selectedNode;

  // Student list panel toggle
  bool _showStudentList = false;

  // Subscription for new unverified student notifications
  StreamSubscription<NetworkNode>? _newStudentSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleHost = Provider.of<BleHostService>(context, listen: false);
      bleHost.resetNodes();
      bleHost.startAdvertising();

      // Subscribe to new unverified student events
      _newStudentSub = bleHost.onNewUnverifiedStudent.listen((node) {
        if (mounted) {
          _showNewStudentBanner(node);
        }
      });
    });
  }

  void _showNewStudentBanner(NetworkNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint,
                    color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${node.displayName} needs fingerprint',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Roll: ${node.rollNumber} • Ask student to verify',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    _newStudentSub?.cancel();
    super.dispose();
  }

  void _showNodeDetails(NetworkNode node) {
    setState(() => _selectedNode = node);
    final currentNode = _selectedNode ?? node;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (currentNode.status) {
      case NodeStatus.verifiedGreen:
        statusColor = const Color(0xFF10B981);
        statusText = 'Connected & Verified';
        statusIcon = Icons.verified_user_rounded;
        break;
      case NodeStatus.unverifiedYellow:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Awaiting Fingerprint';
        statusIcon = Icons.fingerprint;
        break;
      case NodeStatus.disconnectedRed:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Signal Lost';
        statusIcon = Icons.bluetooth_disabled_rounded;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final lastSeenFormatted =
            DateFormat('hh:mm:ss a').format(currentNode.lastSeenAt);
        final firstSeenFormatted =
            DateFormat('hh:mm:ss a').format(currentNode.firstSeenAt);

        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.3),
                              statusColor.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(statusIcon,
                            color: statusColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentNode.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Roll: ${currentNode.rollNumber}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fingerprint prompt if unverified
                  if (currentNode.status == NodeStatus.unverifiedYellow)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Color(0xFFF59E0B), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ask the student to hold fingerprint on their BlueBand to verify attendance.',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(),
                  const SizedBox(height: 4),

                  // Telemetry rows
                  _buildDetailRow(ctx,
                      icon: Icons.bluetooth_audio_rounded,
                      label: 'Signal Strength',
                      value:
                          '${currentNode.rssi} dBm (${currentNode.signalQuality})',
                      valueColor: currentNode.rssi >= -75
                          ? const Color(0xFF10B981)
                          : (currentNode.rssi >= -85
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444))),
                  _buildDetailRow(ctx,
                      icon: Icons.timer_outlined,
                      label: 'Active Attended Time',
                      value: currentNode.formatAttendedDuration(),
                      valueColor: const Color(0xFF38BDF8)),
                  _buildDetailRow(ctx,
                      icon: Icons.fingerprint,
                      label: 'Fingerprint Status',
                      value: currentNode.verified
                          ? 'VERIFIED 🟢'
                          : 'NOT VERIFIED 🔴',
                      valueColor: currentNode.verified
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444)),
                  _buildDetailRow(ctx,
                      icon: Icons.access_time_filled_rounded,
                      label: 'First Detected',
                      value: firstSeenFormatted),
                  _buildDetailRow(ctx,
                      icon: Icons.history_rounded,
                      label: 'Last Heartbeat',
                      value: lastSeenFormatted),
                  _buildDetailRow(ctx,
                      icon: Icons.numbers_rounded,
                      label: 'Total Pings',
                      value: '${currentNode.pingCount} packets'),
                  _buildDetailRow(ctx,
                      icon: Icons.warning_amber_rounded,
                      label: 'Disconnections',
                      value: '${currentNode.disconnectCount}×',
                      valueColor: currentNode.disconnectCount > 0
                          ? const Color(0xFFEF4444)
                          : null),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('End Attendance Session?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will freeze all live presence tracking, compile attendance percentages, and generate the final report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End & Save Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bleHost =
          Provider.of<BleHostService>(context, listen: false);
      final attendanceService =
          Provider.of<AttendanceService>(context, listen: false);

      final liveNodes = Map<String, NetworkNode>.from(bleHost.nodes);
      final activeSessionId = attendanceService.activeSession?.id;

      await bleHost.stopAdvertising();
      await attendanceService.endSession(liveNodes);

      if (mounted && activeSessionId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionReportScreen(
              sessionId: activeSessionId,
              sessionName: widget.sessionName,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleHost = Provider.of<BleHostService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final nodesList = bleHost.nodes.values.toList();

    // Correctly count only ACTIVE nodes
    final connectedCount =
        nodesList.where((n) => n.isConnected).length;
    final verifiedCount = nodesList
        .where((n) => n.verified && n.status == NodeStatus.verifiedGreen)
        .length;
    final unverifiedCount =
        nodesList.where((n) => n.status == NodeStatus.unverifiedYellow).length;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sessionName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$verifiedCount verified · $connectedCount active · ${nodesList.length} total',
              style: const TextStyle(
                  color: Color(0xFF10B981), fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Unverified alert badge
          if (unverifiedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fingerprint,
                        size: 13,
                        color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '$unverifiedCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Student list toggle
          IconButton(
            tooltip: 'Student List',
            icon: Icon(_showStudentList
                ? Icons.grid_view_rounded
                : Icons.list_alt_rounded),
            onPressed: () =>
                setState(() => _showStudentList = !_showStudentList),
          ),

          // Theme toggle
          IconButton(
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            icon: Icon(isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => themeProvider.toggleTheme(),
          ),

          // BLE scan badge
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (bleHost.isScanning
                        ? const Color(0xFF10B981)
                        : Colors.orangeAccent)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: bleHost.isScanning
                      ? const Color(0xFF10B981)
                      : Colors.orangeAccent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth_searching,
                      size: 13,
                      color: bleHost.isScanning
                          ? const Color(0xFF10B981)
                          : Colors.orangeAccent),
                  const SizedBox(width: 4),
                  Text(
                    bleHost.isScanning ? 'SCAN' : 'IDLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: bleHost.isScanning
                          ? const Color(0xFF10B981)
                          : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // End session
          IconButton(
            tooltip: 'End Session & Save',
            icon: const Icon(Icons.stop_circle_rounded,
                color: Colors.redAccent, size: 26),
            onPressed: _endSession,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _showStudentList
            ? _buildStudentListPanel(context, nodesList, isDark)
            : _buildNetworkCanvas(context, nodesList, isDark),
      ),
    );
  }

  // ─────────────────── Network Canvas View ────────────────────────
  Widget _buildNetworkCanvas(
      BuildContext context, List<NetworkNode> nodesList, bool isDark) {
    return Stack(
      key: const ValueKey('canvas'),
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.4,
          maxScale: 2.5,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return GestureDetector(
                onTapUp: (details) {
                  final renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPos = details.localPosition;
                  final center = Offset(
                      renderBox.size.width / 2,
                      renderBox.size.height / 2);

                  for (var node in nodesList) {
                    final nodePos = center + Offset(node.x, node.y);
                    if ((localPos - nodePos).distance < 45) {
                      _showNodeDetails(node);
                      break;
                    }
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: MaterialMeshGraphPainter(
                    nodes: nodesList,
                    pulseValue: _pulseController.value,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Top info banner ──
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: _buildInfoBanner(context, nodesList),
        ),

        // ── Legend ──
        Positioned(
          bottom: 20,
          left: 16,
          child: _buildLegend(context),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(
      BuildContext context, List<NetworkNode> nodesList) {
    final active = nodesList.where((n) => n.isConnected).length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  size: 15, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tap any node to view details',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$active Active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardColor.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem(
                  const Color(0xFF10B981), 'Verified Present'),
              const SizedBox(height: 5),
              _buildLegendItem(
                  const Color(0xFFF59E0B), 'Needs Fingerprint'),
              const SizedBox(height: 5),
              _buildLegendItem(
                  const Color(0xFFEF4444), 'Signal Lost (fading)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────── Student List View ──────────────────────────
  Widget _buildStudentListPanel(
      BuildContext context, List<NetworkNode> nodesList, bool isDark) {
    if (nodesList.isEmpty) {
      return Center(
        key: const ValueKey('list'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_searching,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Waiting for students to connect…',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Sort: verified first, then unverified, then disconnected
    final sorted = [...nodesList]..sort((a, b) {
        int rankOf(NodeStatus s) {
          if (s == NodeStatus.verifiedGreen) return 0;
          if (s == NodeStatus.unverifiedYellow) return 1;
          return 2;
        }
        return rankOf(a.status).compareTo(rankOf(b.status));
      });

    return ListView.separated(
      key: const ValueKey('list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = sorted[index];
        return _buildStudentListTile(context, node);
      },
    );
  }

  Widget _buildStudentListTile(BuildContext context, NetworkNode node) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (node.status) {
      case NodeStatus.verifiedGreen:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.verified_user_rounded;
        statusLabel = 'Verified';
        break;
      case NodeStatus.unverifiedYellow:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.fingerprint;
        statusLabel = 'Unverified';
        break;
      case NodeStatus.disconnectedRed:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.bluetooth_disabled_rounded;
        statusLabel = 'Disconnected';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNodeDetails(node),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.3),
                      statusColor.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    node.name.isNotEmpty
                        ? node.name[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Roll: ${node.rollNumber}',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon,
                            color: statusColor, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node.formatAttendedDuration(),
                    style: TextStyle(
                      color: const Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────── Canvas Painter ────────────────────────────────

class MaterialMeshGraphPainter extends CustomPainter {
  final List<NetworkNode> nodes;
  final double pulseValue;
  final bool isDark;

  MaterialMeshGraphPainter({
    required this.nodes,
    required this.pulseValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Radar rings
    for (int r = 1; r <= 3; r++) {
      final ringRadius = (r * 110.0) + (pulseValue * 25.0);
      final ringPaint = Paint()
        ..color = (isDark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF0284C7))
            .withValues(alpha: 0.06 * (1.0 - (pulseValue * 0.4)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // 2. Node lines, particles, and node circles
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final nodePos = center + Offset(node.x, node.y);

      Color nodeColor;
      switch (node.status) {
        case NodeStatus.verifiedGreen:
          nodeColor = const Color(0xFF10B981);
          break;
        case NodeStatus.unverifiedYellow:
          nodeColor = const Color(0xFFF59E0B);
          break;
        case NodeStatus.disconnectedRed:
          nodeColor = const Color(0xFFEF4444);
          break;
      }

      // Line
      final linePaint = Paint()
        ..color = nodeColor
            .withValues(alpha: node.isConnected ? 0.35 : 0.1)
        ..strokeWidth = node.isConnected ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodePos, linePaint);

      // Animated particle on active lines
      if (node.isConnected) {
        final particleT = (pulseValue + (i * 0.2)) % 1.0;
        final particlePos = Offset.lerp(center, nodePos, particleT)!;
        final particlePaint = Paint()
          ..color = nodeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(particlePos, 3.5, particlePaint);
      }

      // Outer pulse glow
      if (node.isConnected) {
        final glowRadius = 24.0 + (pulseValue * 8.0);
        final glowPaint = Paint()
          ..color = nodeColor.withValues(alpha: 0.18 * (1 - pulseValue))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodePos, glowRadius, glowPaint);
      }

      // Border ring
      canvas.drawCircle(
        nodePos,
        20,
        Paint()
          ..color = nodeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Core
      canvas.drawCircle(
        nodePos,
        18,
        Paint()
          ..color = isDark ? const Color(0xFF131C2E) : Colors.white
          ..style = PaintingStyle.fill,
      );

      // Initial letter
      final initials =
          node.name.isNotEmpty ? node.name[0].toUpperCase() : 'S';
      _drawText(
        canvas,
        text: initials,
        position: nodePos,
        style: TextStyle(
          color: nodeColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      // Badge background
      const badgeWidth = 140.0;
      const badgeHeight = 44.0;
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: nodePos + const Offset(0, 48),
          width: badgeWidth,
          height: badgeHeight,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = (isDark ? const Color(0xFF131C2E) : Colors.white)
              .withValues(alpha: 0.95)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Badge label
      _drawText(
        canvas,
        text: '${node.rollNumber} • ${node.displayName}',
        position: nodePos + const Offset(0, 34),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        maxWidth: badgeWidth - 10,
      );

      // Badge sub-label
      final statusInfo = node.isConnected
          ? '${node.rssi} dBm • ⏱ ${node.formatAttendedDuration()}'
          : 'DISCONNECTED • ⏱ ${node.formatAttendedDuration()}';
      _drawText(
        canvas,
        text: statusInfo,
        position: nodePos + const Offset(0, 48),
        style: TextStyle(
          color: nodeColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // 3. Teacher root node
    final rootPulseRadius = 42.0 + (pulseValue * 14.0);
    canvas.drawCircle(
      center,
      rootPulseRadius,
      Paint()
        ..color = (isDark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF0284C7))
            .withValues(alpha: 0.22 * (1.0 - pulseValue))
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      32,
      Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      32,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    _drawText(
      canvas,
      text: 'HOST',
      position: center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset position,
    required TextStyle style,
    double? maxWidth,
  }) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth ?? double.infinity);
    painter.paint(
        canvas, position - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MaterialMeshGraphPainter oldDelegate) => true;
}

