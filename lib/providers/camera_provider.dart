import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/detection_models.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  String _cameraUrl = '';
  String _cameraType = 'phone';
  final ApiService _apiService = ApiService();

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String get cameraUrl => _cameraUrl;
  String get cameraType => _cameraType;

  Future<void> initializeCamera() async {
    try {
      // Load saved settings
      final settings = await DatabaseService.instance.getSettings();
      if (settings != null) {
        _cameraUrl = settings.cameraUrl;
        _cameraType = settings.cameraType;
      }

      if (_cameraType == 'phone') {
        await _initializePhoneCamera();
      } else {
        await _initializeIPCamera();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializePhoneCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initializeIPCamera() async {
    // For IP camera, we'll use the video feed from Python backend
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startDetection() async {
    if (!_isInitialized) return;

    try {
      final success = await _apiService.startDetection(_cameraUrl, _cameraType);
      if (success) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error starting detection: $e');
    }
  }

  Future<void> stopDetection() async {
    try {
      final success = await _apiService.stopDetection();
      if (success) {
        _isRecording = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error stopping detection: $e');
    }
  }

  Future<void> updateCameraSettings({
    required String url,
    required String type,
  }) async {
    _cameraUrl = url;
    _cameraType = type;

    // Get current threshold settings
    final currentSettings = await DatabaseService.instance.getSettings();
    final drowsinessThreshold = currentSettings?.drowsinessThreshold ?? 0.7;
    final speedThreshold = currentSettings?.speedThreshold ?? 60.0;

    // Save to database with preserved threshold values
    final settings = CameraSettings(
      cameraUrl: url,
      cameraType: type,
      drowsinessThreshold: drowsinessThreshold,
      speedThreshold: speedThreshold,
    );
    await DatabaseService.instance.saveSettings(settings);

    // Reinitialize camera
    await disposeCamera();
    await initializeCamera();
    notifyListeners();
  }

  Future<String> getVideoFeedUrl() async {
    return await _apiService.getCameraFeedUrl();
  }

  Future<void> disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}