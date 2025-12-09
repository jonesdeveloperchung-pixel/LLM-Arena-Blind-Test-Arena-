// lib/core/models/backup_file_model.dart
import 'package:flutter/foundation.dart'; // For @immutable

@immutable
class BackupFile {
  final String filename;

  const BackupFile({
    required this.filename,
  });

  factory BackupFile.fromJson(String filename) {
    return BackupFile(filename: filename);
  }

  String toJson() {
    return filename;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupFile &&
          runtimeType == other.runtimeType &&
          filename == other.filename);

  @override
  int get hashCode => filename.hashCode;

  @override
  String toString() {
    return 'BackupFile{filename: $filename}';
  }
}
