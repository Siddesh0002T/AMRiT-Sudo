import 'package:flutter/material.dart';
import '../services/ble_client_service.dart';

class LedIndicatorWidget extends StatefulWidget {
  final BandConnectionStatus status;

  const LedIndicatorWidget({super.key, required this.status});

  @override
  State<LedIndicatorWidget> createState() => _LedIndicatorWidgetState();
}

class _LedIndicatorWidgetState extends State<LedIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String statusText;

    switch (widget.status) {
      case BandConnectionStatus.connectedGreen:
        color = const Color(0xFF00FF88);
        statusText = 'LIVE';
        break;
      case BandConnectionStatus.connectingYellow:
        color = const Color(0xFFFFCC00);
        statusText = 'PAIRING';
        break;
      case BandConnectionStatus.disconnectedRed:
        color = const Color(0xFFFF4466);
        statusText = 'OFFLINE';
        break;
    }

    final bool isPulsing =
        widget.status != BandConnectionStatus.disconnectedRed;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowOpacity =
            isPulsing ? 0.3 + (_pulseController.value * 0.5) : 0.2;
        final dotScale =
            isPulsing ? 0.9 + (_pulseController.value * 0.1) : 1.0;

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: dotScale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: glowOpacity),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

