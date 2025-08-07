import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detection_models.dart';
import '../services/database_service.dart';

class ApiService {
  static const Duration timeout = Duration(seconds: 5);
  String _serverUrl = 'http://localhost:8000'; // Default value, will be updated from settings

  ApiService() {
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final settings = await DatabaseService.instance.getSettings();
    if (settings != null) {
      _serverUrl = settings.serverUrl;
    }
  }

  Future<String> getServerUrl() async {
    if (_serverUrl == 'http://localhost:8000') {
      // If still using default, try to load from settings
      await _loadServerUrl();
    }
    return _serverUrl;
  }

  // Start detection stream
  Future<bool> startDetection(String cameraUrl, String cameraType) async {
    try {
      final serverUrl = await getServerUrl();
      final response = await http.post(
        Uri.parse('$serverUrl/start_detection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'camera_url': cameraUrl,
          'camera_type': cameraType,
        }),
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error starting detection: $e');
      return false;
    }
  }

  // Stop detection stream
  Future<bool> stopDetection() async {
    try {
      final serverUrl = await getServerUrl();
      final response = await http.post(
        Uri.parse('$serverUrl/stop_detection'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error stopping detection: $e');
      return false;
    }
  }

  // Get detection status
  Future<Map<String, dynamic>?> getDetectionStatus() async {
    try {
      final serverUrl = await getServerUrl();
      final response = await http.get(
        Uri.parse('$serverUrl/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting status: $e');
    }
    return null;
  }

  // Stream alerts from Python backend
  Stream<AlertData> getAlertStream() {
    final controller = StreamController<AlertData>();
    Timer? timer;

    void fetchAlerts() async {
      try {
        final serverUrl = await getServerUrl();
        final response = await http.get(
          Uri.parse('$serverUrl/alerts'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['has_alert'] == true) {
            final alert = AlertData.fromJson(data['alert']);
            controller.add(alert);
          }
        }
      } catch (e) {
        print('Error fetching alerts: $e');
      }
    }

    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      fetchAlerts();
    });

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  // Update detection thresholds
  Future<bool> updateThresholds({
    required double drowsinessThreshold,
    required double speedThreshold,
  }) async {
    try {
      final serverUrl = await getServerUrl();
      final response = await http.post(
        Uri.parse('$serverUrl/update_thresholds'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'drowsiness_threshold': drowsinessThreshold,
          'speed_threshold': speedThreshold,
        }),
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating thresholds: $e');
      return false;
    }
  }

  // Health check
  Future<bool> isServerHealthy() async {
    try {
      final serverUrl = await getServerUrl();
      final response = await http.get(
        Uri.parse('$serverUrl/health'),
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get camera feed URL
  Future<String> getCameraFeedUrl() async {
    final serverUrl = await getServerUrl();
    return '$serverUrl/video_feed';
  }
}