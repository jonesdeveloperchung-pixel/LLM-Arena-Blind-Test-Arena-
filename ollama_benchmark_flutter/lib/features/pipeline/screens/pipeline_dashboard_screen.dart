import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'dart:async'; // For Timer
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:pub_semver/pub_semver.dart'; // Import pub_semver
import '../../../core/providers.dart'; // Import providers.dart
import '../../../core/models/pipeline_item_model.dart'; // Import PipelineItem model
import 'model_management_view.dart'; // Import ModelManagementView
import 'review_detail_view.dart'; // Import ReviewDetailView


class PipelineDashboardScreen extends ConsumerStatefulWidget {
  const PipelineDashboardScreen({super.key});

  @override
  ConsumerState<PipelineDashboardScreen> createState() => _PipelineDashboardScreenState();
}

class _PipelineDashboardScreenState extends ConsumerState<PipelineDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer; // For periodic polling

  // Pipeline Status State
  Map<String, dynamic> _pipelineStats = {
    "status": "loading",
    "pending_items": 0,
    "total_processed": 0,
    "approved_items": 0,
    "rejected_items": 0,
    "avg_processing_time": 0.0,
    "uptime": "N/A"
  };
  bool _ollamaHealthy = false;
  bool _daemonRunning = false; // New state for daemon status
  bool _isFetching = false; // New state to track if data is currently being fetched
  
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Increased to 4 tabs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(telemetryServiceProvider).trackEvent('pipeline', 'switch_tab', details: {'tab_index': _tabController.index});
      }
    });

    // Start fetching data and polling
    _manualRefresh(); // Call manual refresh once to fetch data and start timer
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchPipelineStatus();
      _fetchDaemonStatus();
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _manualRefresh() async {
    _stopPolling(); // Stop polling before manual refresh
    await _fetchPipelineStatus();
    await _fetchDaemonStatus();
    _startPolling(); // Restart polling after manual refresh
  }

  @override
  void dispose() {
    _stopPolling(); // Ensure timer is cancelled when widget is disposed
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPipelineStatus() async {
    final apiClient = ref.read(apiClientProvider);
    if (mounted) {
      setState(() {
        _isFetching = true;
      });
    }
    try {
      final status = await apiClient.getPipelineStatus();
      final ollamaHealth = await apiClient.checkOllamaHealth();
      if (mounted) {
        setState(() {
          _pipelineStats = status;
          _ollamaHealthy = ollamaHealth;
        });
      }
    } catch (e) {
      ref.read(telemetryServiceProvider).trackEvent('pipeline', 'fetch_status_failure', error: e.toString());
      if (mounted) {
        setState(() {
          _pipelineStats['status'] = 'error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _fetchDaemonStatus() async {
    final apiClient = ref.read(apiClientProvider);
    if (mounted) {
      setState(() {
        _isFetching = true; // Set fetching state
      });
    }
    try {
      final status = await apiClient.get('/daemon/status'); // Assuming get method handles this
      if (mounted) {
        setState(() {
          _daemonRunning = status['running'] ?? false;
        });
      }
    } catch (e) {
      ref.read(telemetryServiceProvider).trackEvent('daemon', 'fetch_status_failure', error: e.toString());
      if (mounted) {
        setState(() {
          _daemonRunning = false; // Assume not running if API call fails
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false; // Reset fetching state
        });
      }
    }
  }

  Future<void> _toggleDaemon() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    try {
      if (_daemonRunning) {
        await apiClient.post('/daemon/stop');
        telemetry.trackEvent('daemon', 'stop_daemon_success');
        _showSnackBar('Daemon stopped.');
      } else {
        await apiClient.post('/daemon/start');
        telemetry.trackEvent('daemon', 'start_daemon_success');
        _showSnackBar('Daemon started.');
      }
      _fetchDaemonStatus(); // Refresh status after action
    } catch (e) {
      telemetry.trackEvent('daemon', 'toggle_daemon_failure', error: e.toString());
      _showSnackBar('Failed to toggle daemon: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inherit global dark theme for Pipeline
    return Scaffold(
        appBar: AppBar(
          title: const Text('圖像處理管道 (Pipeline)'),
          backgroundColor: Theme.of(context).colorScheme.surface, // Use theme's surface color
          foregroundColor: Theme.of(context).colorScheme.onSurface, // Use theme's onSurface color
          elevation: 1,
          actions: [
            if (_isFetching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isFetching ? null : _manualRefresh,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary, // Use theme's primary color
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Use theme's onSurface with opacity
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: '儀表板 (Dashboard)'),
              Tab(icon: Icon(Icons.list), text: '待審核 (Queue)'),
              Tab(icon: Icon(Icons.settings), text: '設定 (Settings)'),
              Tab(icon: Icon(Icons.model_training), text: '模型管理 (Models)'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DashboardView(
              pipelineStats: _pipelineStats, 
              ollamaHealthy: _ollamaHealthy,
              daemonRunning: _daemonRunning, // Pass daemon status
              onToggleDaemon: _toggleDaemon, // Pass toggle function
            ),
            QueueView(showSnackBar: _showSnackBar), // Pass _showSnackBar
            SettingsView(showSnackBar: _showSnackBar),
            ModelManagementView(showSnackBar: _showSnackBar), // Pass _showSnackBar
          ],
        ),
    );
  }
}

class DashboardView extends StatelessWidget {
  final Map<String, dynamic> pipelineStats;
  final bool ollamaHealthy;
  final bool daemonRunning;
  final VoidCallback onToggleDaemon; // Callback for daemon toggle

  const DashboardView({
    super.key, 
    required this.pipelineStats, 
    required this.ollamaHealthy,
    required this.daemonRunning,
    required this.onToggleDaemon,
  });

  @override
  Widget build(BuildContext context) {
    final totalProcessed = pipelineStats['total_processed'] ?? 0;
    final pendingItems = pipelineStats['pending_items'] ?? 0;
    final approvedItems = pipelineStats['approved_items'] ?? 0;
    final rejectedItems = pipelineStats['rejected_items'] ?? 0;
    final avgProcessingTime = pipelineStats['avg_processing_time'] ?? 0.0;
    // final uptime = pipelineStats['uptime'] ?? "N/A"; // Uptime from backend not accurate without daemon

    final total = totalProcessed + pendingItems; // Approximation for now
    final approvedRate = total > 0 ? ((approvedItems / total) * 100).toStringAsFixed(1) : '0.0';

    final data = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pendingItems.toDouble(), color: Colors.orange, width: 20)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: approvedItems.toDouble(), color: Colors.green, width: 20)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: rejectedItems.toDouble(), color: Colors.red, width: 20)]),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: StatCard(title: '總處理量', value: totalProcessed.toString(), icon: Icons.analytics, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: '待審核', value: pendingItems.toString(), icon: Icons.pending_actions, color: Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: '核准率', value: '$approvedRate%', icon: Icons.check_circle, color: Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: '平均處理時間', value: '${avgProcessingTime.toStringAsFixed(0)} ms', icon: Icons.timer, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          // Charts
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('狀態分佈 (Status)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                barGroups: data,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        switch (val.toInt()) {
                                          case 0: return Text('Pending', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color));
                                          case 1: return Text('Approved', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color));
                                          case 2: return Text('Rejected', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color));
                                        }
                                        return Text('', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color));
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide Y-axis titles
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top titles
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right titles
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                    strokeWidth: 1,
                                  ),
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), width: 1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('系統健康度 (Health)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          const SizedBox(height: 16),
                          _buildHealthItem(
                            'Daemon Service', 
                            daemonRunning ? 'Running' : 'Stopped', 
                            daemonRunning ? Colors.green : Colors.grey,
                            trailingWidget: Switch(value: daemonRunning, onChanged: (val) => onToggleDaemon()),
                          ),
                          _buildHealthItem('Database (SQLite)', 'Connected', Colors.green),
                          _buildHealthItem(
                            'Ollama API', 
                            ollamaHealthy ? 'Healthy' : 'Disconnected', 
                            ollamaHealthy ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, String status, Color color, {Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
          if (trailingWidget != null)
            trailingWidget
          else
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class QueueView extends ConsumerStatefulWidget {
  final Function(String, {bool isError}) showSnackBar;

  const QueueView({super.key, required this.showSnackBar});

  @override
  ConsumerState<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends ConsumerState<QueueView> {
  List<PipelineItem> _pipelineItems = [];
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPipelineItems();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchPipelineItems();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPipelineItems() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await apiClient.getPipelineItems();
      if (mounted) {
        setState(() {
          _pipelineItems = (items as List).map((e) => PipelineItem.fromJson(e)).toList();
        });
        telemetry.trackEvent('queue_view', 'fetch_items_success', details: {'count': items.length});
      }
    } catch (e) {
      telemetry.trackEvent('queue_view', 'fetch_items_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to load pipeline items: $e', isError: true);
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _pipelineItems.isEmpty
            ? const Center(child: Text('沒有待處理的項目 (No pending items)'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pipelineItems.length,
                itemBuilder: (context, index) {
                  final item = _pipelineItems[index];
                  return Card(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Theme.of(context).colorScheme.surfaceVariant, // Use a theme-agnostic color
                        child: Icon(Icons.image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      title: Text(item.filename), // Use item.filename
                      subtitle: Text('Status: ${item.status}'), // Use item.status
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ref.read(telemetryServiceProvider).trackEvent('queue_view', 'view_item_details', details: {'item_id': item.id}); // Use item.id
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewDetailView(itemId: item.id), // Use item.id
                          ),
                        ).then((_) => _fetchPipelineItems()); // Refresh when returning
                      },
                    ),
                  );
                },
              );
  }
}

class SettingsView extends ConsumerStatefulWidget {
  final Function(String, {bool isError}) showSnackBar;

  const SettingsView({super.key, required this.showSnackBar});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _useGeminiFallback = false;
  String _ollamaUrl = 'http://localhost:11434';
  String _ollamaModel = 'llama3.2-vision';
  String _geminiApiKey = '';
  double _autoApproveConfidence = 0.85;
  String _inputDir = 'input'; // New state for input_dir
  bool _isGeminiApiKeyVisible = false; // New state for API key visibility

  String _currentAppVersion = 'Loading...';
  String _latestAvailableVersion = 'Unknown';
  bool _isUpdateAvailable = false;
  bool _isCheckingForUpdate = false;

  TextEditingController _ollamaUrlController = TextEditingController();
  TextEditingController _ollamaModelController = TextEditingController();
  TextEditingController _geminiApiKeyController = TextEditingController();
  TextEditingController _autoApproveConfidenceController = TextEditingController();
  TextEditingController _inputDirController = TextEditingController(); // New controller


  @override
  void initState() {
    super.initState();
    _fetchConfig();
    _fetchCurrentAppVersion();
  }

  Future<void> _fetchConfig() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final config = await apiClient.get('/config'); // Assuming API Client has a general GET
      if (mounted) {
        setState(() {
          _ollamaUrl = config['ollama']['url'] ?? 'http://localhost:11434';
          _ollamaModel = config['ollama']['model'] ?? 'llama3.2-vision';
          _useGeminiFallback = config['gemini']['fallback_on_ollama_failure'] ?? false;
          _geminiApiKey = config['gemini']['api_key'] ?? '';
          _autoApproveConfidence = (config['processing']['auto_approve_confidence'] as num?)?.toDouble() ?? 0.85;
          _inputDir = config['paths']['input'] ?? 'input'; // Fetch input_dir

          _ollamaUrlController.text = _ollamaUrl;
          _ollamaModelController.text = _ollamaModel;
          _geminiApiKeyController.text = _geminiApiKey;
          _autoApproveConfidenceController.text = _autoApproveConfidence.toString();
          _inputDirController.text = _inputDir; // Set input_dir controller
        });
      }
    } catch (e) {
      ref.read(telemetryServiceProvider).trackEvent('settings', 'fetch_config_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to load configuration: $e', isError: true);
      }
    }
  }

  Future<void> _saveConfig() async {
    ref.read(telemetryServiceProvider).trackEvent('settings', 'save_config');
    setState(() {
      _ollamaUrl = _ollamaUrlController.text;
      _ollamaModel = _ollamaModelController.text;
      _geminiApiKey = _geminiApiKeyController.text;
      _autoApproveConfidence = double.tryParse(_autoApproveConfidenceController.text) ?? 0.85;
      _inputDir = _inputDirController.text; // Update input_dir state
    });

    final apiClient = ref.read(apiClientProvider);
    try {
      final updatedConfig = {
        "ollama": {
          "url": _ollamaUrl,
          "model": _ollamaModel,
        },
        "gemini": {
          "fallback_on_ollama_failure": _useGeminiFallback,
          "api_key": _geminiApiKey,
        },
        "processing": {
          "auto_approve_confidence": _autoApproveConfidence,
        },
        "paths": { // Include paths section
          "input": _inputDir,
        }
      };
      await apiClient.post('/config', body: updatedConfig); // Assuming API Client has a general POST
      if (mounted) {
        widget.showSnackBar('設定已儲存');
        ref.read(telemetryServiceProvider).trackEvent('settings', 'save_config_success');
      }
    } catch (e) {
      ref.read(telemetryServiceProvider).trackEvent('settings', 'save_config_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to save configuration: $e', isError: true);
      }
    }
  }

  Future<void> _fetchCurrentAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentAppVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Failed to get current app version: $e');
      if (mounted) {
        setState(() {
          _currentAppVersion = 'Error';
        });
      }
    }
  }

  Future<void> _checkForUpdates() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isCheckingForUpdate = true;
      _isUpdateAvailable = false;
      _latestAvailableVersion = 'Checking...';
    });

    try {
      final backendVersion = await apiClient.getLatestAppVersion();
      if (mounted) {
        setState(() {
          _latestAvailableVersion = backendVersion['version'] ?? 'Unknown';
          // Simple version comparison for MVP. A robust solution needs semantic versioning parsing.
          if (_currentAppVersion != 'Loading...' && _currentAppVersion != 'Error' && _latestAvailableVersion != 'Unknown') {
            try {
              final currentVersion = Version.parse(_currentAppVersion);
              final latestVersion = Version.parse(_latestAvailableVersion);
              _isUpdateAvailable = latestVersion > currentVersion;
            } catch (e) {
              // Handle parsing errors, e.g., if version strings are not valid semver
              debugPrint('Error parsing version strings: $e');
              _isUpdateAvailable = false;
            }
          }
        });
        telemetry.trackEvent('settings', 'check_for_updates_success', details: {'current_version': _currentAppVersion, 'latest_version': _latestAvailableVersion, 'update_available': _isUpdateAvailable});
        if (mounted) {
          widget.showSnackBar(_isUpdateAvailable ? '有新版本可用: $_latestAvailableVersion' : '已是最新版本');
        }
      }
    } catch (e) {
      telemetry.trackEvent('settings', 'check_for_updates_failure', error: e.toString());
      if (mounted) {
        setState(() {
          _latestAvailableVersion = 'Error';
          _isUpdateAvailable = false;
        });
        widget.showSnackBar('檢查更新失敗: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdate = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView( // Use ListView for scrollability
            children: [
              Text('系統設定 (Settings)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ollamaUrlController,
                decoration: InputDecoration(
                  labelText: 'Ollama URL',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link, color: Theme.of(context).iconTheme.color),
                ),
                onChanged: (v) => _ollamaUrl = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ollamaModelController,
                decoration: InputDecoration(
                  labelText: 'Ollama Model',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.model_training, color: Theme.of(context).iconTheme.color),
                ),
                onChanged: (v) => _ollamaModel = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _inputDirController, // New input field for input_dir
                decoration: InputDecoration(
                  labelText: '輸入目錄 (Input Directory)',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_open, color: Theme.of(context).iconTheme.color),
                ),
                onChanged: (v) => _inputDir = v,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('啟用 Gemini 備援 (Enable Gemini Fallback)', style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color)),
                subtitle: Text('當 Ollama 失敗時使用 Google Gemini API', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                value: _useGeminiFallback,
                onChanged: (val) {
                  setState(() => _useGeminiFallback = val);
                },
              ), // Added missing comma
              if (_useGeminiFallback) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _geminiApiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key, color: Theme.of(context).iconTheme.color),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isGeminiApiKeyVisible ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGeminiApiKeyVisible = !_isGeminiApiKeyVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isGeminiApiKeyVisible,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _autoApproveConfidenceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '自動批准信心閾值 (Auto Approve Confidence)',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent, color: Theme.of(context).iconTheme.color),
                  suffixText: '(0.0 - 1.0)',
                  suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                onChanged: (v) => _autoApproveConfidence = double.tryParse(v) ?? 0.85,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text('儲存設定 (Save)', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                onPressed: _saveConfig,
              ),
              const SizedBox(height: 32),
              Text('應用程式版本 (App Version)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('目前版本: $_currentAppVersion', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ElevatedButton.icon(
                    onPressed: _isCheckingForUpdate ? null : _checkForUpdates,
                    icon: _isCheckingForUpdate ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, color: Colors.white),
                    label: Text(_isCheckingForUpdate ? '檢查中...' : '檢查更新', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
              if (_isUpdateAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('新版本可用: $_latestAvailableVersion', style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold)),
                )
              else if (!_isCheckingForUpdate && _latestAvailableVersion != 'Unknown' && _latestAvailableVersion != 'Error')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('已是最新版本', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor, // Use theme's card color
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)), // Use theme's text color
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.bodyLarge?.color)), // Use theme's text color
              ],
            ),
          ],
        ),
      ),
    );
  }
}
