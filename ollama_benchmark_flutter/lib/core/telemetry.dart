import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import dart:convert

/// Telemetry Service based on the General Telemetry Specification.
/// Logs execution metadata for analysis and debugging.
class TelemetryService {
  final http.Client _httpClient;
  TelemetryService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  final String _program = 'ollama_benchmark_flutter';
  final String _version = '1.0.0';
  final Uuid _uuid = const Uuid();
  final String _backendUrl = 'http://localhost:8000'; // Backend API base URL

  // In a real app, this might write to a local SQLite DB or a log file.
  // For this prototype, we print to console for "knowing function connectivity".
  void log({
    required String module,
    required String action,
    String? command,
    List<String>? args,
    Map<String, dynamic>? executionMetrics,
    Map<String, dynamic>? context,
    List<String>? tags,
    String? error,
  }) {
    final timestamp = DateTime.now().toUtc();
    
    String user = 'unknown';
    String host = 'unknown';
    String os = 'unknown';
    String cwd = 'unknown';

    try {
      // universal_io handles platform differences safely
      user = Platform.environment['USERNAME'] ?? 'unknown';
      host = Platform.localHostname;
      os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      cwd = Directory.current.path;
    } catch (e) {
      // Fallback if anything fails
      if (kIsWeb) {
        user = 'web_user';
        host = 'browser';
        os = 'web';
      }
    }

    final Map<String, dynamic> logEntry = {
      "timestamp": timestamp.toIso8601String(),
      "program": _program,
      "version": _version,
      "command": command ?? action,
      "module": module,
      "action": action,
      "args": args != null ? jsonEncode(args) : null, // Convert list to JSON string
      "user": user,
      "host": host,
      "os": os,
      "runtime": "Flutter/Dart",
      "execution_duration_ms": executionMetrics?['duration_ms'],
      "execution_exit_code": error != null ? 1 : 0,
      "execution_error": error,
      "context_cwd": cwd,
      "context_details": context != null ? jsonEncode(context) : null, // Convert map to JSON string
      "tags": tags != null ? jsonEncode(tags) : null, // Convert list to JSON string
    };

    if (kDebugMode) {
      print('[TELEMETRY]: ${jsonEncode(logEntry)}');
    }
    
    _sendTelemetryEvent(logEntry);
  }

  Future<void> _sendTelemetryEvent(Map<String, dynamic> logEntry) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_backendUrl/telemetry/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logEntry),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to send telemetry event: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending telemetry event: $e');
    }
  }
  
  void trackEvent(String module, String action, {Map<String, dynamic>? details, String? error}) {
    log(module: module, action: action, context: details, error: error);
  }
}
