import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:llm_arena_blind_test_arena/l10n/app_localizations.dart'; // Import AppLocalizations
import '../../../core/providers.dart'; // Import providers.dart
import 'historical_trends_screen.dart'; // Import the new historical trends screen
import 'report_export_screen.dart'; // Import the new report export screen
import 'side_by_side_arena_screen.dart';
import 'blind_test_arena_screen.dart';
import '../../telemetry/telemetry_dashboard_screen.dart';
import 'ollama_model_management_screen.dart'; // Import the new Ollama model management screen

class BenchmarkHomeScreen extends ConsumerStatefulWidget {
  const BenchmarkHomeScreen({super.key});

  @override
  ConsumerState<BenchmarkHomeScreen> createState() => _BenchmarkHomeScreenState();
}

class _BenchmarkHomeScreenState extends ConsumerState<BenchmarkHomeScreen> {
  String _selectedCategory = 'Reasoning';
  String _selectedModel = 'Llama 3.2'; // New state for selected model
  List<String> _availableModels = []; // New state for available models
  final Map<String, double?> _scores = {
    'Reasoning': null,
    'Coding': null,
    'Vision': null,
    'Language': null,
    'Embedding': null,
  };
  Map<String, dynamic>? _lastBenchmarkResult; // To store full result for display
  bool _isLoading = false;
  late TextEditingController _promptController; // New: Controller for prompt input
  bool _promptControllerInitialized = false; // Flag to ensure one-time initialization

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

  Future<void> _manualRefresh() async {
    setState(() {
      _isLoading = true;
    });
    // Fetch last benchmark results for ALL categories
    for (String category in _scores.keys) {
      await _fetchLastBenchmarkResult(category);
    }
    await _fetchAvailableModels();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Only call super.initState(); initialization of _promptController moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_promptControllerInitialized) {
      _promptController = TextEditingController(text: AppLocalizations.of(context)!.benchmarkSamplePrompt);
      _promptControllerInitialized = true;
      _manualRefresh(); // Call manual refresh once to fetch data
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableModels() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final models = await apiClient.getOllamaModels();
      if (mounted) {
        setState(() {
          _availableModels = models.map((e) => e['name'].toString()).toList();
          if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
            _selectedModel = _availableModels.first; // Set default if current is not available
          } else if (_availableModels.isEmpty) {
            _selectedModel = 'No Model'; // Handle no models case
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to fetch Ollama models: $e', isError: true);
      }
    }
  }

  Future<void> _fetchLastBenchmarkResult(String category) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('benchmark', 'fetch_last_result', details: {'category': category});
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.getBenchmarkResults(category); // Use the new method
      if (mounted) {
        setState(() {
          if (response != null) {
            _scores[category] = response['score']?.toDouble();
            _lastBenchmarkResult = response;
          } else {
            // No result found for this category, set to default or clear
            _scores[category] = 0.0;
            _lastBenchmarkResult = null;
          }
        });
        telemetry.trackEvent('benchmark', 'fetch_last_result_success', details: {'category': category});
      }
    } catch (e) {
      telemetry.trackEvent('benchmark', 'fetch_last_result_failure', error: e.toString());
      if (mounted) {
        // If there's an actual error (not just 404 handled by getBenchmarkResults)
        setState(() {
          _scores[category] = 0.0; // Set to 0.0 on error
          _lastBenchmarkResult = null;
        });
        _showSnackBar('Failed to fetch benchmark results: $e', isError: true);
      }
    }
  }

  Future<void> _runBenchmark() async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('benchmark', 'start_benchmark_run', details: {'category': _selectedCategory});
    setState(() {
      _isLoading = true;
      _scores[_selectedCategory] = 0.0; // Indicate processing
      _lastBenchmarkResult = null;
    });

    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.post('/benchmark/run', body: {
        'category': _selectedCategory,
        'model': _selectedModel,
        'prompt': _promptController.text, // Include the prompt from the text field
      });

      if (mounted) {
        // Ensure to fetch the latest result after running a new benchmark
        await _fetchLastBenchmarkResult(_selectedCategory); 
        _showSnackBar('Benchmark triggered: ${response['message']}');
        telemetry.trackEvent('benchmark', 'benchmark_run_success', details: {'message': response['message']});
      }
    } catch (e) {
      _showSnackBar('Failed to trigger benchmark: $e', isError: true);
      telemetry.trackEvent('benchmark', 'benchmark_run_failure', error: e.toString());
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
    // Access TelemetryService via Provider as well
    final telemetry = ref.read(telemetryServiceProvider);
    final l10n = AppLocalizations.of(context)!; // Get AppLocalizations instance

    // Map English category names to their localized versions for display
    String getLocalizedCategoryName(String englishCategory) {
      switch (englishCategory) {
        case 'Reasoning': return l10n.benchmarkCategoryReasoning;
        case 'Coding': return l10n.benchmarkCategoryCoding;
        case 'Vision': return l10n.benchmarkCategoryVision;
        case 'Language': return l10n.benchmarkCategoryLanguage;
        case 'Embedding': return l10n.benchmarkCategoryEmbedding;
        default: return englishCategory;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('${l10n.benchmarkAppTitle} - ${getLocalizedCategoryName(_selectedCategory)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _isLoading ? null : _manualRefresh,
          ),
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              telemetry.trackEvent('benchmark', 'view_history_pressed', details: {'category': _selectedCategory});
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoricalTrendsScreen(category: _selectedCategory),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.file_download, color: Theme.of(context).colorScheme.onSurface), // New export button
            onPressed: () {
              telemetry.trackEvent('benchmark', 'export_report_pressed');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportExportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.onSurface), // New Side-by-Side Arena button
            onPressed: () {
              telemetry.trackEvent('benchmark', 'side_by_side_arena_pressed');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SideBySideArenaScreen(), // Removed const
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.balance, color: Theme.of(context).colorScheme.onSurface), // New Blind Test Arena button
            onPressed: () {
              telemetry.trackEvent('benchmark', 'blind_test_arena_pressed');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlindTestArenaScreen(), // Removed const
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: Theme.of(context).colorScheme.onSurface), // New Telemetry Dashboard button
            onPressed: () {
              telemetry.trackEvent('benchmark', 'telemetry_dashboard_pressed');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelemetryDashboardScreen(), // Removed const
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              telemetry.trackEvent('benchmark', 'settings_button_pressed');
              // Implement navigation to settings if needed, or open dialog
            },
          ),
          IconButton(
            icon: Icon(Icons.model_training, color: Theme.of(context).colorScheme.onSurface), // Icon for model management
            onPressed: () {
              telemetry.trackEvent('ollama_management', 'open_model_management_screen');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OllamaModelManagementScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: ListView(
              children: _scores.keys.map((category) {
                final isSelected = _selectedCategory == category;
                final score = _scores[category];
                return ListTile(
                  title: Text(
                    getLocalizedCategoryName(category),
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: score == null
                      ? Text('N/A', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))
                      : score == 0.0
                          ? Text('0.0 ★', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))
                          : Text('${score.toStringAsFixed(1)} ★', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _fetchLastBenchmarkResult(category); // Fetch results for newly selected category
                    telemetry.trackEvent('benchmark', 'category_selected', details: {'category': category});
                  },
                );
              }).toList(),
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedModel = newValue;
                              });
                            }
                          },
                          items: _availableModels.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                                softWrap: false, // Prevent wrapping
                                maxLines: 1, // Ensure single line
                              ),
                            );
                          }).toList(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
                          underline: Container(), // Remove underline
                          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
                        ),
                      ),
                      const SizedBox(width: 16), // Add some spacing
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: _isLoading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2)) : Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.onPrimary),
                          label: Text(_isLoading ? l10n.benchmarkRunningStatus : '執行測試 (Run Test)', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _isLoading ? null : _runBenchmark, // Call _runBenchmark
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Content Grid
                  Expanded(
                    child: Row(
                      children: [
                        // Test Zone / Details
                        Expanded(
                          flex: 2,
                          child: Card(
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('測試提示 (Prompt)', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _promptController,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Enter your prompt here...',
                                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
                                  ),
                                  const Spacer(),
                                  if (_lastBenchmarkResult != null) ...[
                                    Text(l10n.benchmarkJudgesAnalysis, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _lastBenchmarkResult!['reasoning'] ?? 'No reasoning available.',
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8.0, // gap between adjacent chips
                                      runSpacing: 4.0, // gap between lines
                                      children: (_lastBenchmarkResult!['breakdown'] as Map<String, dynamic>).entries.map((entry) {
                                        return Chip(
                                          label: Text('${entry.key}: ${entry.value?.toStringAsFixed(1)} ★'),
                                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                        );
                                      }).toList(),
                                    )
                                  ] else if (_isLoading) ...[
                                    Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                                    const SizedBox(height: 16),
                                    Text(l10n.benchmarkRunningStatus, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                  ] else ...[
                                    Text(l10n.benchmarkNoResults, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Radar Chart Area
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text('能力雷達圖 (Radar Chart)', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: RadarChartWidget(scores: _scores),
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
            ),
          ),
        ],
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  final Map<String, double?> scores;
  const RadarChartWidget({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores == null || scores.isEmpty) {
      return Center(
        child: Text(
          'No score data available',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      );
    }

    final List<String> categoryNames = scores.keys.toList();
    final List<RadarEntry> data = scores.values.map<RadarEntry>((dynamic value) {
      return RadarEntry(value: (value as num?)?.toDouble() ?? 0.0);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderColor: Theme.of(context).colorScheme.primary,
            entryRadius: 2,
            dataEntries: data,
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10),
        getTitle: (index, angle) {
          if (index >= categoryNames.length) return const RadarChartTitle(text: '');
          return RadarChartTitle(text: categoryNames[index]);
        },
        tickCount: 5, // Assuming scores are 0-5
        ticksTextStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        gridBorderData: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 1),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
    );
  }
}

