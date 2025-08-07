import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/detection_models.dart';

class LogsProvider with ChangeNotifier {
  List<DetectionLog> _allLogs = [];
  List<DetectionLog> _filteredLogs = [];
  String _currentFilter = 'all';
  bool _isLoading = false;

  List<DetectionLog> get allLogs => _allLogs;
  List<DetectionLog> get filteredLogs => _filteredLogs;
  String get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allLogs = await DatabaseService.instance.getAllLogs();
      _applyFilter();
    } catch (e) {
      print('Error loading logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case 'drowsiness':
        _filteredLogs = _allLogs.where((log) => log.type == 'drowsiness').toList();
        break;
      case 'speed':
        _filteredLogs = _allLogs.where((log) => log.type == 'speed').toList();
        break;
      case 'all':
      default:
        _filteredLogs = List.from(_allLogs);
        break;
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await DatabaseService.instance.deleteLog(id);
      await loadLogs();
    } catch (e) {
      print('Error deleting log: $e');
    }
  }

  Future<void> clearAllLogs() async {
    try {
      await DatabaseService.instance.clearAllLogs();
      _allLogs.clear();
      _filteredLogs.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }

  int get totalLogsCount => _allLogs.length;
  int get drowsinessLogsCount => _allLogs.where((log) => log.type == 'drowsiness').length;
  int get speedLogsCount => _allLogs.where((log) => log.type == 'speed').length;

  DetectionLog? getLatestLog() {
    return _allLogs.isNotEmpty ? _allLogs.first : null;
  }

  List<DetectionLog> getLogsFromToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _allLogs.where((log) => 
      log.timestamp.isAfter(startOfDay)
    ).toList();
  }

  List<DetectionLog> getLogsFromLastWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return _allLogs.where((log) => 
      log.timestamp.isAfter(weekAgo)
    ).toList();
  }

  Map<String, int> getLogStats() {
    final todayLogs = getLogsFromToday();
    final weekLogs = getLogsFromLastWeek();
    
    return {
      'total': _allLogs.length,
      'today': todayLogs.length,
      'week': weekLogs.length,
      'drowsiness_today': todayLogs.where((log) => log.type == 'drowsiness').length,
      'speed_today': todayLogs.where((log) => log.type == 'speed').length,
    };
  }
}