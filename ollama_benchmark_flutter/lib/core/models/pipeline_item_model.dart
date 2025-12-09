// lib/core/models/pipeline_item_model.dart
import 'package:flutter/foundation.dart';

@immutable
class PipelineItem {
  final String id;
  final String filename;
  final String filepath;
  final String status;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? processingTimeMs;
  final double? confidenceScore;
  final String? description;
  final String? metadataJson;
  final String? detectionRawJson;
  final String? errorMessage;

  const PipelineItem({
    required this.id,
    required this.filename,
    required this.filepath,
    required this.status,
    this.source,
    required this.createdAt,
    required this.updatedAt,
    this.processingTimeMs,
    this.confidenceScore,
    this.description,
    this.metadataJson,
    this.detectionRawJson,
    this.errorMessage,
  });

  factory PipelineItem.fromJson(Map<String, dynamic> json) {
    return PipelineItem(
      id: json['id'] as String,
      filename: json['filename'] as String,
      filepath: json['filepath'] as String,
      status: json['status'] as String,
      source: json['source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      processingTimeMs: json['processing_time_ms'] as int?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      description: json['description'] as String?,
      metadataJson: json['metadata_json'] as String?,
      detectionRawJson: json['detection_raw_json'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'filepath': filepath,
      'status': status,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processing_time_ms': processingTimeMs,
      'confidence_score': confidenceScore,
      'description': description,
      'metadata_json': metadataJson,
      'detection_raw_json': detectionRawJson,
      'error_message': errorMessage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PipelineItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filename == other.filename &&
          filepath == other.filepath &&
          status == other.status &&
          source == other.source &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          processingTimeMs == other.processingTimeMs &&
          confidenceScore == other.confidenceScore &&
          description == other.description &&
          metadataJson == other.metadataJson &&
          detectionRawJson == other.detectionRawJson &&
          errorMessage == other.errorMessage);

  @override
  int get hashCode =>
      id.hashCode ^
      filename.hashCode ^
      filepath.hashCode ^
      status.hashCode ^
      source.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      processingTimeMs.hashCode ^
      confidenceScore.hashCode ^
      description.hashCode ^
      metadataJson.hashCode ^
      detectionRawJson.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'PipelineItem{id: $id, filename: $filename, filepath: $filepath, status: $status, source: $source, createdAt: $createdAt, updatedAt: $updatedAt, processingTimeMs: $processingTimeMs, confidenceScore: $confidenceScore, description: $description, metadataJson: $metadataJson, detectionRawJson: $detectionRawJson, errorMessage: $errorMessage}';
  }
}