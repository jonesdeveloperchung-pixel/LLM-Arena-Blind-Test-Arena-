import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm_arena_blind_test_arena/core/providers.dart';
import 'package:llm_arena_blind_test_arena/core/telemetry.dart';
import 'package:llm_arena_blind_test_arena/core/models/backup_file_model.dart'; // Import the new BackupFile model

class RollbackManagementScreen extends ConsumerStatefulWidget {
  const RollbackManagementScreen({super.key});

  @override
  ConsumerState<RollbackManagementScreen> createState() => _RollbackManagementScreenState();
}

class _RollbackManagementScreenState extends ConsumerState<RollbackManagementScreen> {
  bool _isLoading = false;
  List<BackupFile> _backupFiles = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBackupFiles();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onTertiary)),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  Future<void> _fetchBackupFiles() async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('rollback_management', 'fetch_backups_start');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/config/backups');
      if (mounted) {
        setState(() {
          _backupFiles = (response as List).map((e) => BackupFile.fromJson(e)).toList();
          _isLoading = false;
          _errorMessage = null; // Clear any previous error message on successful load
        });
        telemetry.trackEvent('rollback_management', 'fetch_backups_success', details: {'count': _backupFiles.length});
      }
    } catch (e) {
      telemetry.trackEvent('rollback_management', 'fetch_backups_failure', error: e.toString());
      if (mounted) {
        setState(() {
          if (_backupFiles.isEmpty) { // Only set persistent error if no files to show
            _errorMessage = 'Failed to load backup files: $e';
          }
          _isLoading = false;
        });
        _showSnackBar('Failed to load backup files: $e', isError: true);
      }
    }
  }

  Future<void> _performRollback(String filename) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('rollback_management', 'rollback_start', details: {'filename': filename});
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/config/rollback', body: {'backup_filename': filename});
      if (mounted) {
        _showSnackBar('Successfully restored from backup: $filename');
        telemetry.trackEvent('rollback_management', 'rollback_success', details: {'filename': filename});
        await _fetchBackupFiles(); // Refresh list after rollback
      }
    } catch (e) {
      telemetry.trackEvent('rollback_management', 'rollback_failure', error: e.toString());
      if (mounted) {
        _showSnackBar('Failed to restore from backup $filename: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRollbackConfirmationDialog(String filename) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Confirm Rollback', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
          content: Text('Are you sure you want to restore the configuration from "$filename"? This action cannot be undone.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performRollback(filename);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text('Restore', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 950
      appBar: AppBar(
        title: Text('Rollback Management', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _isLoading ? null : _fetchBackupFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : _backupFiles.isEmpty
                                ? Center(
                                    child: Text(
                                      'No backup files found.',
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                    ),
                                  )
                                : ListView.builder(                      padding: const EdgeInsets.all(16.0),
                      itemCount: _backupFiles.length,
                      itemBuilder: (context, index) {
                        final backupFile = _backupFiles[index];
                        return Card(
                          color: Theme.of(context).cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              backupFile.filename,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            trailing: ElevatedButton(
                              onPressed: _isLoading ? null : () => _showRollbackConfirmationDialog(backupFile.filename),
                              child: const Text('Restore'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
