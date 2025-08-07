import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';
import '../services/database_service.dart';
import '../models/detection_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cameraUrlController = TextEditingController();
  final _serverUrlController = TextEditingController();
  String _selectedCameraType = 'phone';
  double _drowsinessThreshold = 0.7;
  double _speedThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

    _cameraUrlController.text = cameraProvider.cameraUrl;
    _selectedCameraType = cameraProvider.cameraType;
    _drowsinessThreshold = detectionProvider.drowsinessThreshold;
    _speedThreshold = detectionProvider.speedThreshold;
    
    // Load server URL from settings
    final settings = await DatabaseService.instance.getSettings();
    if (settings != null) {
      setState(() {
        _serverUrlController.text = settings.serverUrl;
      });
    }
  }

  @override
  void dispose() {
    _cameraUrlController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCameraSection(),
            const SizedBox(height: 24),
            _buildDetectionSection(),
            const SizedBox(height: 24),
            _buildSystemSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Camera Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Type',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Phone Camera'),
                    value: 'phone',
                    groupValue: _selectedCameraType,
                    onChanged: (value) {
                      setState(() {
                        _selectedCameraType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('IP Camera'),
                    value: 'ip',
                    groupValue: _selectedCameraType,
                    onChanged: (value) {
                      setState(() {
                        _selectedCameraType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_selectedCameraType == 'ip') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _cameraUrlController,
                decoration: const InputDecoration(
                  labelText: 'Camera URL',
                  hintText: 'rtsp://192.168.1.100:554/stream',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (_selectedCameraType == 'ip' && (value == null || value.isEmpty)) {
                    return 'Please enter camera URL';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Drowsiness Detection Threshold',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _drowsinessThreshold,
                    min: 0.5,
                    max: 0.95,
                    divisions: 9,
                    label: '${(_drowsinessThreshold * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        _drowsinessThreshold = value;
                      });
                    },
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(_drowsinessThreshold * 100).toInt()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Speed Limit Threshold (km/h)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _speedThreshold,
                    min: 30,
                    max: 120,
                    divisions: 18,
                    label: '${_speedThreshold.toInt()} km/h',
                    onChanged: (value) {
                      setState(() {
                        _speedThreshold = value;
                      });
                    },
                  ),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_speedThreshold.toInt()} km/h',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Higher threshold = less sensitive detection\nLower threshold = more sensitive detection',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Server URL',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Backend Server URL',
                hintText: 'http://192.168.1.100:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer2<CameraProvider, DetectionProvider>(
              builder: (context, cameraProvider, detectionProvider, child) {
                return Column(
                  children: [
                    _buildStatusRow(
                      'Camera Status',
                      cameraProvider.isInitialized ? 'Connected' : 'Disconnected',
                      cameraProvider.isInitialized ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'AI Server Status',
                      detectionProvider.serverConnected ? 'Online' : 'Offline',
                      detectionProvider.serverConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Detection Status',
                      detectionProvider.isDetecting ? 'Active' : 'Inactive',
                      detectionProvider.isDetecting ? Colors.blue : Colors.grey,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Consumer<DetectionProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      await provider.refreshServerConnection();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.serverConnected 
                                  ? 'Server connection refreshed' 
                                  : 'Failed to connect to server',
                            ),
                            backgroundColor: 
                                provider.serverConnected ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
      final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving settings...'),
            ],
          ),
        ),
      );

      // Save server URL to database
      final settings = CameraSettings(
        cameraUrl: _cameraUrlController.text,
        cameraType: _selectedCameraType,
        drowsinessThreshold: _drowsinessThreshold,
        speedThreshold: _speedThreshold,
        serverUrl: _serverUrlController.text,
      );
      await DatabaseService.instance.saveSettings(settings);

      // Update camera settings
      await cameraProvider.updateCameraSettings(
        url: _cameraUrlController.text,
        type: _selectedCameraType,
      );

      // Update detection thresholds
      await detectionProvider.updateThresholds(
        drowsiness: _drowsinessThreshold,
        speed: _speedThreshold,
      );

      // Restart the app to apply server URL changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved. Restart the app to apply server URL changes.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Return to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}