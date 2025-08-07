import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/logs_provider.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'System Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<DetectionProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isDetecting ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.isDetecting ? 'MONITORING' : 'STOPPED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Camera',
                    Consumer<CameraProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          provider.isInitialized ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: provider.isInitialized ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'AI Server',
                    Consumer<DetectionProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          provider.serverConnected ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: provider.serverConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildThresholdItem(
                    context,
                    'Drowsiness',
                    Consumer<DetectionProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${(provider.drowsinessThreshold * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _buildThresholdItem(
                    context,
                    'Speed Limit',
                    Consumer<DetectionProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.speedThreshold.toInt()} km/h',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            Consumer<LogsProvider>(
              builder: (context, provider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  provider.loadLogs();
                });
                
                final stats = provider.getLogStats();
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Today', stats['today']?.toString() ?? '0'),
                    _buildStatItem('This Week', stats['week']?.toString() ?? '0'),
                    _buildStatItem('Total', stats['total']?.toString() ?? '0'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  Widget _buildThresholdItem(BuildContext context, String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}