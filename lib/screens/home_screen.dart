import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../widgets/camera_widget.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/status_panel.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);
    
    await cameraProvider.initializeCamera();
    await detectionProvider.refreshServerConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Driver Safety Monitor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          Consumer<DetectionProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: provider.serverConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.serverConnected ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logs':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LogsScreen()),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logs',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('View Logs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Feed
          const Positioned.fill(
            child: CameraWidget(),
          ),
          
          // Alert Overlay
          const Positioned.fill(
            child: AlertOverlay(),
          ),
          
          // Status Panel
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: StatusPanel(),
          ),
        ],
      ),
      floatingActionButton: Consumer2<CameraProvider, DetectionProvider>(
        builder: (context, cameraProvider, detectionProvider, child) {
          return FloatingActionButton.extended(
            onPressed: () => _toggleDetection(cameraProvider, detectionProvider),
            backgroundColor: detectionProvider.isDetecting 
                ? Colors.red.shade600 
                : Colors.green.shade600,
            icon: Icon(
              detectionProvider.isDetecting ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              detectionProvider.isDetecting ? 'Stop Monitoring' : 'Start Monitoring',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _toggleDetection(CameraProvider cameraProvider, DetectionProvider detectionProvider) async {
    if (!cameraProvider.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not initialized'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!detectionProvider.serverConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server not connected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (detectionProvider.isDetecting) {
      await detectionProvider.stopDetection();
      await cameraProvider.stopDetection();
    } else {
      await cameraProvider.startDetection();
      await detectionProvider.startDetection();
    }
  }
}