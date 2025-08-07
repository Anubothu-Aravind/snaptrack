import 'dart:convert';

class DetectionLog {
  final int? id;
  final String type; // 'drowsiness' or 'speed'
  final String message;
  final DateTime timestamp;
  final double? confidence;
  final double? speed;

  DetectionLog({
    this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.confidence,
    this.speed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'confidence': confidence,
      'speed': speed,
    };
  }

  factory DetectionLog.fromMap(Map<String, dynamic> map) {
    return DetectionLog(
      id: map['id'],
      type: map['type'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      confidence: map['confidence'],
      speed: map['speed'],
    );
  }
  
  // JSON serialization for web platform
  String toJson() {
    return json.encode(toMap());
  }
  
  factory DetectionLog.fromJson(String source) {
    return DetectionLog.fromMap(json.decode(source));
  }
}

class AlertData {
  final String type;
  final String message;
  final double confidence;
  final DateTime timestamp;

  AlertData({
    required this.type,
    required this.message,
    required this.confidence,
    required this.timestamp,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      type: json['type'],
      message: json['message'],
      confidence: json['confidence'].toDouble(),
      timestamp: DateTime.now(),
    );
  }
}

class CameraSettings {
  final String cameraUrl;
  final String cameraType; // 'phone' or 'ip'
  final double drowsinessThreshold;
  final double speedThreshold;
  final String serverUrl;

  CameraSettings({
    required this.cameraUrl,
    required this.cameraType,
    this.drowsinessThreshold = 0.7,
    this.speedThreshold = 60.0,
    this.serverUrl = 'http://localhost:8000',
  });

  Map<String, dynamic> toMap() {
    return {
      'cameraUrl': cameraUrl,
      'cameraType': cameraType,
      'drowsinessThreshold': drowsinessThreshold,
      'speedThreshold': speedThreshold,
      'serverUrl': serverUrl,
    };
  }

  factory CameraSettings.fromMap(Map<String, dynamic> map) {
    return CameraSettings(
      cameraUrl: map['cameraUrl'],
      cameraType: map['cameraType'],
      drowsinessThreshold: map['drowsinessThreshold'],
      speedThreshold: map['speedThreshold'],
      serverUrl: map['serverUrl'] ?? 'http://localhost:8000',
    );
  }
  
  // JSON serialization for web platform
  String toJson() {
    return json.encode(toMap());
  }
  
  factory CameraSettings.fromJson(String source) {
    return CameraSettings.fromMap(json.decode(source));
  }
}