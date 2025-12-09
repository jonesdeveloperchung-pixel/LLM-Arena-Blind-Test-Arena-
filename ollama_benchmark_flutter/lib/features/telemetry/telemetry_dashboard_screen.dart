import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../../../core/providers.dart'; // For apiClientProvider and telemetryServiceProvider

class TelemetryDashboardScreen extends ConsumerStatefulWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  ConsumerState<TelemetryDashboardScreen> createState() => _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState extends ConsumerState<TelemetryDashboardScreen> {
  List<dynamic> _telemetryLogs = [];
  bool _isLoading = true;
  String? _selectedProgramFilter;
  String? _selectedModuleFilter;
  String? _selectedActionFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  // Example filters (would be dynamic in a real app based on fetched logs)
  final List<String> _availablePrograms = ['ollama_benchmark_flutter', 'backend'];
  final List<String> _availableModules = ['api_client', 'benchmark', 'pipeline', 'daemon', 'settings', 'queue_view', 'review_detail', 'model_management', 'historical_trends', 'report_export', 'side_by_side_arena'];
  final List<String> _availableActions = ['http_get', 'http_post', 'http_delete', 'fetch_status', 'toggle_daemon', 'run_benchmark', 'fetch_models', 'pull_model', 'delete_model', 'fetch_items', 'view_item_details', 'update_item', 'generate_report', 'download_report', 'compare_models'];


  @override
  void initState() {
    super.initState();
    _fetchTelemetryLogs();
  }

  Future<void> _fetchTelemetryLogs() async {
    final apiClient = ref.read(apiClientProvider);
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await apiClient.get(
        '/telemetry/logs', // This will be adjusted to take filters
        // TODO: Pass filters here once the API client method is updated
      );
      if (mounted) {
        setState(() {
          _telemetryLogs = logs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load telemetry logs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('遙測儀表板 (Telemetry Dashboard)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilterOptions(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _telemetryLogs.isEmpty
                    ? const Center(child: Text('沒有找到遙測日誌 (No telemetry logs found)'))
                    : ListView.builder(
                        itemCount: _telemetryLogs.length,
                        itemBuilder: (context, index) {
                          final log = _telemetryLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(log['timestamp']))} - ${log['program']} v${log['version']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Module: ${log['module']} | Action: ${log['action']}'),
                                  if (log['command'] != null && log['command'] != log['action']) Text('Command: ${log['command']}'),
                                  if (log['execution_error'] != null) Text('Error: ${log['execution_error']}', style: const TextStyle(color: Colors.red)),
                                  if (log['context_details'] != null) Text('Details: ${log['context_details']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('篩選日誌 (Filter Logs)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                DropdownButton<String>(
                  hint: const Text('程式 (Program)'),
                  value: _selectedProgramFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedProgramFilter = value;
                    });
                    _fetchTelemetryLogs();
                  },
                  items: _availablePrograms.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                DropdownButton<String>(
                  hint: const Text('模組 (Module)'),
                  value: _selectedModuleFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedModuleFilter = value;
                    });
                    _fetchTelemetryLogs();
                  },
                  items: _availableModules.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                DropdownButton<String>(
                  hint: const Text('動作 (Action)'),
                  value: _selectedActionFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedActionFilter = value;
                    });
                    _fetchTelemetryLogs();
                  },
                  items: _availableActions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
                    if (picked != null) {
                      setState(() {
                        _startDateFilter = picked;
                      });
                      _fetchTelemetryLogs();
                    }
                  },
                  child: Text(_startDateFilter == null ? '開始日期' : DateFormat('yyyy-MM-dd').format(_startDateFilter!)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
                    if (picked != null) {
                      setState(() {
                        _endDateFilter = picked;
                      });
                      _fetchTelemetryLogs();
                    }
                  },
                  child: Text(_endDateFilter == null ? '結束日期' : DateFormat('yyyy-MM-dd').format(_endDateFilter!)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedProgramFilter = null;
                      _selectedModuleFilter = null;
                      _selectedActionFilter = null;
                      _startDateFilter = null;
                      _endDateFilter = null;
                    });
                    _fetchTelemetryLogs();
                  },
                  child: const Text('清除篩選 (Clear Filters)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}