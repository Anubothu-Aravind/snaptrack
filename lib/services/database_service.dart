import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    
    // Use different storage approach based on platform
    if (kIsWeb) {
      // Web platform doesn't support sqflite
      // Initialize shared preferences or other web storage
      print('Using web storage instead of SQLite');
      return null; // No actual database on web
    } else {
      // Mobile platforms use SQLite
      _database = await _initDB('detection_logs.db');
      return _database!;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE detection_logs (
        id $idType,
        type $textType,
        message $textType,
        timestamp $integerType,
        confidence $realType,
        speed $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id $idType,
        camera_url $textType,
        camera_type $textType,
        drowsiness_threshold $realType,
        speed_threshold $realType,
        server_url $textType DEFAULT 'http://localhost:8000'
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add server_url column to settings table
      await db.execute('''
        ALTER TABLE settings 
        ADD COLUMN server_url TEXT NOT NULL DEFAULT 'http://localhost:8000'
      ''');
    }
  }

  Future<int> insertLog(DetectionLog log) async {
    if (kIsWeb) {
      // Web implementation using shared preferences or other storage
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('logs') ?? [];
      logs.add(log.toJson());
      await prefs.setStringList('logs', logs);
      return logs.length; // Return the new length as ID
    } else {
      // Mobile implementation using SQLite
      final db = await instance.database;
      return await db.insert('detection_logs', log.toMap());
    }
  }

  Future<List<DetectionLog>> getAllLogs() async {
    if (kIsWeb) {
      // Web implementation
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('logs') ?? [];
      final detectionLogs = logs.map((json) => DetectionLog.fromJson(json)).toList();
      
      // Sort with null safety
      detectionLogs.sort((a, b) {
        if (a == null || b == null) return 0;
        if (a.timestamp == null) return 1; // Null timestamps go to the end
        if (b.timestamp == null) return -1;
        return b.timestamp.compareTo(a.timestamp); // Sort by timestamp DESC
      });
      
      return detectionLogs;
    } else {
      // Mobile implementation
      final db = await instance.database;
      const orderBy = 'timestamp DESC';
      final result = await db.query('detection_logs', orderBy: orderBy);
      return result.map((json) => DetectionLog.fromMap(json)).toList();
    }
  }

  Future<List<DetectionLog>> getLogsByType(String type) async {
    if (kIsWeb) {
      // Web implementation
      final allLogs = await getAllLogs();
      return allLogs.where((log) => log.type == type).toList();
    } else {
      // Mobile implementation
      final db = await instance.database;
      final result = await db.query(
        'detection_logs',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'timestamp DESC',
      );
      return result.map((json) => DetectionLog.fromMap(json)).toList();
    }
  }

  Future<int> deleteLog(int id) async {
    if (kIsWeb) {
      // Web implementation
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('logs') ?? [];
      final detectionLogs = logs.map((json) => DetectionLog.fromJson(json)).toList();
      
      // Find and remove the log with the given id
      final initialLength = detectionLogs.length;
      detectionLogs.removeWhere((log) => log.id == id);
      
      // Save the updated logs
      await prefs.setStringList('logs', 
          detectionLogs.map((log) => log.toJson()).toList());
      
      return initialLength - detectionLogs.length; // Return number of deleted items
    } else {
      // Mobile implementation
      final db = await instance.database;
      return await db.delete(
        'detection_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> clearAllLogs() async {
    if (kIsWeb) {
      // Web implementation
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logs');
    } else {
      // Mobile implementation
      final db = await instance.database;
      await db.delete('detection_logs');
    }
  }

  Future<void> saveSettings(CameraSettings settings) async {
    if (kIsWeb) {
      // Web implementation
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings', settings.toJson());
    } else {
      // Mobile implementation
      final db = await instance.database;
      await db.delete('settings'); // Clear existing settings
      await db.insert('settings', {
        'camera_url': settings.cameraUrl,
        'camera_type': settings.cameraType,
        'drowsiness_threshold': settings.drowsinessThreshold,
        'speed_threshold': settings.speedThreshold,
        'server_url': settings.serverUrl,
      });
    }
  }

  Future<CameraSettings?> getSettings() async {
    if (kIsWeb) {
      // Web implementation
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('settings');
      if (settingsJson != null) {
        return CameraSettings.fromJson(settingsJson);
      }
      return null;
    } else {
      // Mobile implementation
      final db = await instance.database;
      final result = await db.query('settings', limit: 1);
      if (result.isNotEmpty) {
        return CameraSettings.fromMap(result.first);
      }
      return null;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}