import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/logs_provider.dart';
import '../models/detection_models.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LogsProvider>(context, listen: false).loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Logs'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = Provider.of<LogsProvider>(context, listen: false);
              if (value == 'clear') {
                _showClearConfirmDialog(provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Logs', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<LogsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildFilterTabs(provider),
              _buildStatsPanel(provider),
              Expanded(
                child: provider.filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(LogsProvider provider) {
    return Container(
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(
              'All',
              'all',
              provider.currentFilter == 'all',
              provider.totalLogsCount,
              provider,
            ),
          ),
          Expanded(
            child: _buildFilterTab(
              'Drowsiness',
              'drowsiness',
              provider.currentFilter == 'drowsiness',
              provider.drowsinessLogsCount,
              provider,
            ),
          ),
          Expanded(
            child: _buildFilterTab(
              'Speed',
              'speed',
              provider.currentFilter == 'speed',
              provider.speedLogsCount,
              provider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String label,
    String filter,
    bool isSelected,
    int count,
    LogsProvider provider,
  ) {
    return GestureDetector(
      onTap: () => provider.setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade800 : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue.shade800 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(LogsProvider provider) {
    final stats = provider.getLogStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today', stats['today']?.toString() ?? '0'),
          _buildStatItem('This Week', stats['week']?.toString() ?? '0'),
          _buildStatItem('Drowsiness Today', stats['drowsiness_today']?.toString() ?? '0'),
          _buildStatItem('Speed Today', stats['speed_today']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogsList(LogsProvider provider) {
    return ListView.builder(
      itemCount: provider.filteredLogs.length,
      itemBuilder: (context, index) {
        final log = provider.filteredLogs[index];
        return _buildLogItem(log, provider);
      },
    );
  }

  Widget _buildLogItem(DetectionLog log, LogsProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLogColor(log.type),
          child: Icon(
            _getLogIcon(log.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          log.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(log.timestamp),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (log.confidence != null)
              Text(
                'Confidence: ${(log.confidence! * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            if (log.speed != null)
              Text(
                'Speed: ${log.speed!.toStringAsFixed(1)} km/h',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmDialog(log, provider),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No logs found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start monitoring to see detection logs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'drowsiness':
        return Colors.red.shade600;
      case 'speed':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'drowsiness':
        return Icons.bedtime;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.warning;
    }
  }

  void _showDeleteConfirmDialog(DetectionLog log, LogsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteLog(log.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(LogsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text(
          'Are you sure you want to delete all log entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.clearAllLogs();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}