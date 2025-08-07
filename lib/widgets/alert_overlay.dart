import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';

class AlertOverlay extends StatefulWidget {
  const AlertOverlay({super.key});

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        if (provider.currentAlert == null) {
          _slideController.reverse();
          return const SizedBox.shrink();
        }

        _slideController.forward();
        
        final alert = provider.currentAlert!;
        final alertColor = _getAlertColor(alert.type);
        
        return Stack(
          children: [
            // Full screen colored overlay
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: alertColor.withOpacity(0.3 * _pulseAnimation.value),
                );
              },
            ),
            
            // Alert message card
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildAlertCard(alert, alertColor),
              ),
            ),
            
            // Center warning icon
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: alertColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: alertColor.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getAlertIcon(alert.type),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(alert, Color alertColor) {
    return Card(
      elevation: 8,
      color: alertColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getAlertTitle(alert.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(alert.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Provider.of<DetectionProvider>(context, listen: false)
                    .clearAlert();
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'drowsiness':
        return Colors.red.shade600;
      case 'speed':
        return Colors.orange.shade600;
      default:
        return Colors.yellow.shade600;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'drowsiness':
        return Icons.bedtime;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.warning;
    }
  }

  String _getAlertTitle(String type) {
    switch (type) {
      case 'drowsiness':
        return 'DROWSINESS DETECTED';
      case 'speed':
        return 'OVERSPEEDING DETECTED';
      default:
        return 'ALERT';
    }
  }
}