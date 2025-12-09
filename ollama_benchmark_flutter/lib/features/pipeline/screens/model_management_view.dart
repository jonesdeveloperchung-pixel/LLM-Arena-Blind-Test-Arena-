import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart'; // For apiClientProvider and telemetryServiceProvider

class ModelManagementView extends ConsumerStatefulWidget {
  final Function(String, {bool isError}) showSnackBar;

  const ModelManagementView({super.key, required this.showSnackBar});

  @override
  ConsumerState<ModelManagementView> createState() => _ModelManagementViewState();
}

class _ModelManagementViewState extends ConsumerState<ModelManagementView> {
  List<dynamic> _ollamaModels = [];
  bool _isLoadingModels = false;
  String _pullModelName = '';

  @override
  void initState() {
    super.initState();
    _fetchOllamaModels();
  }

  Future<void> _fetchOllamaModels() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await apiClient.getOllamaModels();
      if (mounted) {
        setState(() {
          _ollamaModels = models;
        });
        telemetry.trackEvent('model_management', 'fetch_models_success', details: {'message': 'Found ${models.length} models'});
      }
    } catch (e) {
      telemetry.trackEvent('model_management', 'fetch_models_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to load Ollama models: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  Future<void> _pullOllamaModel() async {
    if (_pullModelName.isEmpty) {
      widget.showSnackBar('Please enter a model name to pull.', isError: true);
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoadingModels = true; // Indicate loading during pull operation
    });

    try {
      final response = await apiClient.pullOllamaModel(_pullModelName);
      if (mounted) {
        widget.showSnackBar('Pull initiated: ${response['message']}');
        telemetry.trackEvent('model_management', 'pull_model_success', details: {'model_name': _pullModelName});
        _pullModelName = ''; // Clear input
        _fetchOllamaModels(); // Refresh list
      }
    } catch (e) {
      telemetry.trackEvent('model_management', 'pull_model_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to pull model: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  Future<void> _deleteOllamaModel(String modelName) async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Confirm Deletion', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
          content: Text('Are you sure you want to delete model "$modelName"? This action cannot be undone.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoadingModels = true; // Indicate loading during delete operation
    });

    try {
      final response = await apiClient.deleteOllamaModel(modelName);
      if (mounted) {
        widget.showSnackBar('Deletion initiated: ${response['message']}');
        telemetry.trackEvent('model_management', 'delete_model_success', details: {'model_name': modelName});
        _fetchOllamaModels(); // Refresh list
      }
    } catch (e) {
      telemetry.trackEvent('model_management', 'delete_model_failure', error: e.toString());
      if (mounted) {
        widget.showSnackBar('Failed to delete model: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ollama 模型管理 (Model Management)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 24),          
          // Pull Model Section
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => _pullModelName = value,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    labelText: '模型名稱 (e.g., llama3, llama3:8b)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: _isLoadingModels ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                label: Text(_isLoadingModels ? '下載中...' : '下載模型 (Pull Model)'),
                onPressed: _isLoadingModels ? null : _pullOllamaModel,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Installed Models List
          const Text('已安裝模型 (Installed Models)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _isLoadingModels
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: _ollamaModels.isEmpty
                      ? Center(child: Text('沒有找到已安裝的 Ollama 模型', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                      : ListView.builder(
                          itemCount: _ollamaModels.length,
                          itemBuilder: (context, index) {
                            final model = _ollamaModels[index];
                            return Card(
                              color: Theme.of(context).cardColor,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(model['name'] ?? 'Unknown Model', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Size: ${model['size'] != null ? '${(model['size'] / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB' : 'N/A'}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                    Text('Modified: ${model['modified_at'] ?? 'N/A'}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                  onPressed: () => _deleteOllamaModel(model['name']),
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
}