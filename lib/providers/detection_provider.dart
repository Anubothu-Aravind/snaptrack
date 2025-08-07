import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/detection_models.dart';

class DetectionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription<AlertData>? _alertSubscription;
  
  bool _isDetecting = false;
  bool _serverConnected = false;
  AlertData? _currentAlert;
  List<DetectionLog> _recentLogs = [];
  double _drowsinessThreshold = 0.7;
  double _speedThreshold = 60.0;

  bool get isDetecting => _isDetecting;
  bool get serverConnected => _serverConnected;
  AlertData? get currentAlert => _currentAlert;
  List<DetectionLog> get recentLogs => _recentLogs;
  double get drowsinessThreshold => _drowsinessThreshold;
  double get speedThreshold => _speedThreshold;

  DetectionProvider() {
    _loadSettings();
    _checkServerHealth();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseService.instance.getSettings();
    if (settings != null) {
      _drowsinessThreshold = settings.drowsinessThreshold;
      _speedThreshold = settings.speedThreshold;
      notifyListeners();
    }
  }

  Future<void> _checkServerHealth() async {
    _serverConnected = await _apiService.isServerHealthy();
    notifyListeners();
  }

  Future<void> startDetection() async {
    if (_isDetecting) return;

    _isDetecting = true;
    notifyListeners();

    // Start listening to alerts
    _alertSubscription = _apiService.getAlertStream().listen(
      (alert) => _handleAlert(alert),
      onError: (error) {
        print('Alert stream error: $error');
        _isDetecting = false;
        notifyListeners();
      },
    );

    // Load recent logs
    await _loadRecentLogs();
  }

  Future<void> stopDetection() async {
    if (!_isDetecting) return;

    _isDetecting = false;
    _currentAlert = null;
    await _alertSubscription?.cancel();
    _alertSubscription = null;
    notifyListeners();
  }

  void _handleAlert(AlertData alert) async {
    _currentAlert = alert;
    notifyListeners();

    // Save to database
    final log = DetectionLog(
      type: alert.type,
      message: alert.message,
      timestamp: alert.timestamp,
      confidence: alert.confidence,
    );

    await DatabaseService.instance.insertLog(log);
    await _loadRecentLogs();

    // Clear alert after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (_currentAlert == alert) {
        _currentAlert = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadRecentLogs() async {
    _recentLogs = await DatabaseService.instance.getAllLogs();
    notifyListeners();
  }

  Future<void> updateThresholds({
    required double drowsiness,
    required double speed,
  }) async {
    _drowsinessThreshold = drowsiness;
    _speedThreshold = speed;

    // Update server
    await _apiService.updateThresholds(
      drowsinessThreshold: drowsiness,
      speedThreshold: speed,
    );

    // Save to database
    final settings = CameraSettings(
      cameraUrl: '',
      cameraType: 'phone',
      drowsinessThreshold: drowsiness,
      speedThreshold: speed,
    );
    await DatabaseService.instance.saveSettings(settings);

    notifyListeners();
  }

  Future<void> clearAlert() async {
    _currentAlert = null;
    notifyListeners();
  }

  bool isAlertActive() {
    return _currentAlert != null;
  }

  String getAlertColor() {
    if (_currentAlert == null) return 'normal';
    switch (_currentAlert!.type) {
      case 'drowsiness':
        return 'red';
      case 'speed':
        return 'orange';
      default:
        return 'yellow';
    }
  }

  Future<void> refreshServerConnection() async {
    await _checkServerHealth();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }
}