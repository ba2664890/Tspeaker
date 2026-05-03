import 'package:flutter/foundation.dart';

/// Singleton that stores log lines and notifies UI listeners.
class DebugLogger extends ChangeNotifier {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<String> _logs = [];

  List<String> get logs => List.unmodifiable(_logs);

  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');
    if (_logs.length > 200) _logs.removeAt(0); // Keep last 200 lines
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
