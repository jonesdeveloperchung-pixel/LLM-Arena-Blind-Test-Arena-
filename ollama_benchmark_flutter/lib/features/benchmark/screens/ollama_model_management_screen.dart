import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart'; // Import providers.dart

class OllamaModelManagementScreen extends ConsumerStatefulWidget {
  const OllamaModelManagementScreen({super.key});

  @override
  ConsumerState<OllamaModelManagementScreen> createState() => _OllamaModelManagementScreenState();
}

final GlobalKey<RefreshIndicatorState> refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

class _OllamaModelManagementScreenState extends ConsumerState<OllamaModelManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _ollamaModels = []; // To store the list of models

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOllamaModels();
    });
  }

  void _showSnackBar(String message) {
    if (mounted) { // Ensure widget is still in tree
      // Access context only if widget is mounted and after build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Re-check mounted after frame callback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    }
  }

  Future<void> _fetchOllamaModels() async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('ollama_management', 'fetch_models_start');
    setState(() {
      _isLoading = true;
    });

    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get('/ollama/models'); // Call the backend endpoint
      if (mounted) {
        setState(() {
          _ollamaModels = response;
          _isLoading = false;
        });
        telemetry.trackEvent('ollama_management', 'fetch_models_success');
      }
    } catch (e) {
      telemetry.trackEvent('ollama_management', 'fetch_models_failure', error: e.toString());
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to load Ollama models: $e');
      }
    }
  }

  Future<void> _pullModel(String modelName) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('ollama_management', 'pull_model_start', details: {'model_name': modelName});
    setState(() {
      _isLoading = true;
    });

    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/ollama/pull', body: {'model_name': modelName});
      if (mounted) {
        _showSnackBar('Pulling $modelName... This may take a while.');
        telemetry.trackEvent('ollama_management', 'pull_model_success', details: {'model_name': modelName});
        _fetchOllamaModels(); // Refresh list after pull
      }
    } catch (e) {
      telemetry.trackEvent('ollama_management', 'pull_model_failure', error: e.toString());
      if (mounted) {
        _showSnackBar('Failed to pull model $modelName: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteModel(String modelName) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('ollama_management', 'delete_model_start', details: {'model_name': modelName});
    setState(() {
      _isLoading = true;
    });

    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/ollama/delete', body: {'model_name': modelName});
      if (mounted) {
        _showSnackBar('Deleted $modelName.');
        telemetry.trackEvent('ollama_management', 'delete_model_success', details: {'model_name': modelName});
        _fetchOllamaModels(); // Refresh list after delete
      }
    } catch (e) {
      telemetry.trackEvent('ollama_management', 'delete_model_failure', error: e.toString());
      if (mounted) {
        _showSnackBar('Failed to delete model $modelName: $e');
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
      backgroundColor: const Color(0xFF0F172A), // Slate 950
      appBar: AppBar(
        title: const Text('Ollama Model Management'),
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchOllamaModels,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ollamaModels.isEmpty
              ? const Center(
                  child: Text(
                    'No Ollama models found. Is Ollama running?',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  key: refreshIndicatorKey,
                  onRefresh: _fetchOllamaModels,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _ollamaModels.length,
                    itemBuilder: (context, index) {
                      final model = _ollamaModels[index];
                      return Card(
                        color: const Color(0xFF1E293B), // Slate 800
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Model: ${model['model'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                              Text('Size: ${model['size'] != null ? '${(model['size'] / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB' : 'N/A'}', style: const TextStyle(color: Colors.white70)),
                              Text('Modified: ${model['modified_at'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _isLoading ? null : () => _deleteModel(model['name']),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Pull/Update'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _isLoading ? null : () => _pullModel(model['name']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () {
          // Show a dialog to input model name to pull
          _showPullModelDialog();
        },
        label: const Text('Pull New Model'),
        icon: const Icon(Icons.cloud_download),
        backgroundColor: const Color(0xFF34D399),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showPullModelDialog() {
    final TextEditingController modelNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pull Ollama Model'),
          content: TextField(
            controller: modelNameController,
            decoration: const InputDecoration(hintText: "e.g., llama3:8b"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Pull'),
              onPressed: () {
                Navigator.of(context).pop();
                if (modelNameController.text.isNotEmpty) {
                  _pullModel(modelNameController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }
}