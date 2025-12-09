// lib/core/models/alert_model.dart
import 'package:flutter/foundation.dart';

@immutable
class Alert {
  final int id;
  final DateTime timestamp;
  final String source;
  final String message;
  final String severity;
  final Map<String, dynamic>? details;
  final String status;

  const Alert({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.message,
    required this.severity,
    this.details,
    required this.status,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      details: json['details'] as Map<String, dynamic>?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'message': message,
      'severity': severity,
      'details': details,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          source == other.source &&
          message == other.message &&
          severity == other.severity &&
          mapEquals(details, other.details) &&
          status == other.status);

  @override
  int get hashCode =>
      id.hashCode ^
      timestamp.hashCode ^
      source.hashCode ^
      message.hashCode ^
      severity.hashCode ^
      details.hashCode ^
      status.hashCode;

  @override
  String toString() {
    return 'Alert{id: $id, timestamp: $timestamp, source: $source, message: $message, severity: $severity, details: $details, status: $status}';
  }
}
