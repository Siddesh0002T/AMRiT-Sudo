import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';

class FingerprintButtonWidget extends StatefulWidget {
  final VoidCallback onVerificationChanged;

  const FingerprintButtonWidget({super.key, required this.onVerificationChanged});

  @override
  State<FingerprintButtonWidget> createState() =>
      _FingerprintButtonWidgetState();
}

class _FingerprintButtonWidgetState extends State<FingerprintButtonWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _successController;
  late AnimationController _orbitController;
  Timer? _holdTimer;
  bool _isHolding = false;

  // For particle burst
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeSimulatedVerification();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    _orbitController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onPressDown(TapDownDetails details) {
    setState(() => _isHolding = true);
    _progressController.forward(from: 0.0);
    HapticFeedback.lightImpact();
  }

  void _onPressUp() {
    if (_progressController.status != AnimationStatus.completed) {
      _cancelHold();
    }
  }

  void _onPressCancel() => _cancelHold();

  void _cancelHold() {
    setState(() => _isHolding = false);
    _progressController.reverse();
  }

  void _completeSimulatedVerification() {
    HapticFeedback.heavyImpact();
    _spawnParticles();
    _successController.forward(from: 0.0);
    final bioService = Provider.of<BiometricService>(context, listen: false);
    bioService.setVerifiedSimulated(true);
    widget.onVerificationChanged();
    setState(() => _isHolding = false);
  }

  void _spawnParticles() {
    final rng = math.Random();
    _particles.clear();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        angle: rng.nextDouble() * 2 * math.pi,
        speed: 60 + rng.nextDouble() * 60,
        color: [
          const Color(0xFF00FF88),
          const Color(0xFF00C8FF),
          const Color(0xFFFFCC00),
        ][rng.nextInt(3)],
        size: 4 + rng.nextDouble() * 4,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioService = Provider.of<BiometricService>(context);
    final isVerified = bioService.isVerified;

    final primaryColor =
        isVerified ? const Color(0xFF00FF88) : const Color(0xFF00C8FF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: isVerified ? null : _onPressDown,
          onTapUp: isVerified ? null : (_) => _onPressUp(),
          onTapCancel: isVerified ? null : _onPressCancel,
          onTap: () async {
            if (!isVerified) {
              final ok = await bioService.authenticateBiometric();
              if (ok) {
                _spawnParticles();
                _successController.forward(from: 0.0);
                widget.onVerificationChanged();
              }
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_progressController, _successController, _orbitController]),
            builder: (context, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── Orbiting Ring (always visible when not verified) ──
                    if (!isVerified)
                      Transform.rotate(
                        angle: _orbitController.value * 2 * math.pi,
                        child: Container(
                          width: 154,
                          height: 154,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.7),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Outer Glow Ring ──
                    Container(
                      width: 142,
                      height: 142,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 
                            isVerified ? 0.12 : 0.06),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 
                              isVerified ? 0.9 : 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 
                                isVerified ? 0.4 : 0.15),
                            blurRadius: 28,
                            spreadRadius: isVerified ? 6 : 3,
                          ),
                        ],
                      ),
                    ),

                    // ── Progress Arc while holding ──
                    if (_isHolding)
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _progressController.value,
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          backgroundColor: Colors.white10,
                          strokeCap: StrokeCap.round,
                        ),
                      ),

                    // ── Success burst ring ──
                    if (isVerified)
                      Opacity(
                        opacity:
                            1.0 - _successController.value.clamp(0.0, 1.0),
                        child: Container(
                          width: 142 +
                              _successController.value * 30,
                          height: 142 +
                              _successController.value * 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                    // ── Particle Burst ──
                    ..._particles.map((p) {
                      final progress = _successController.value;
                      final dx = math.cos(p.angle) * p.speed * progress;
                      final dy = math.sin(p.angle) * p.speed * progress;
                      return Opacity(
                        opacity: (1.0 - progress).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(dx, dy),
                          child: Container(
                            width: p.size,
                            height: p.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.color,
                              boxShadow: [
                                BoxShadow(
                                  color: p.color.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // ── Inner Sensor Core ──
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isVerified
                              ? [
                                  const Color(0xFF00FF88).withValues(alpha: 0.3),
                                  const Color(0xFF0A1020)
                                ]
                              : [
                                  primaryColor.withValues(alpha: 
                                      _isHolding
                                          ? 0.3 + _progressController.value * 0.2
                                          : 0.15),
                                  const Color(0xFF0A1020),
                                ],
                        ),
                      ),
                      child: Icon(
                        isVerified
                            ? Icons.fingerprint_rounded
                            : Icons.fingerprint,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // ── Status Text ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isVerified ? 'FINGERPRINT VERIFIED ✓' : 'VERIFICATION REQUIRED',
            key: ValueKey(isVerified),
            style: TextStyle(
              color: isVerified
                  ? const Color(0xFF00FF88)
                  : const Color(0xFF00C8FF),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isVerified
              ? 'Biometric token attached to active BLE heartbeats'
              : 'Tap for hardware fingerprint · hold 1.5s for manual',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),

        if (isVerified) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              bioService.reset();
              widget.onVerificationChanged();
            },
            icon: const Icon(Icons.refresh_rounded,
                size: 14, color: Colors.grey),
            label: const Text(
              'Reset Verification',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

