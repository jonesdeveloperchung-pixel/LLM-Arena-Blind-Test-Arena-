import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart'; // For image upload
import 'package:path/path.dart' as p; // For path manipulation
import 'dart:io' as io; // For File operations

import '../../../core/providers.dart';
import '../../../core/telemetry.dart';

class SideBySideArenaScreen extends ConsumerStatefulWidget {
  const SideBySideArenaScreen({super.key});

  @override
  ConsumerState<SideBySideArenaScreen> createState() => _SideBySideArenaScreenState();
}

class _SideBySideArenaScreenState extends ConsumerState<SideBySideArenaScreen> {
  String? _model1;
  String? _model2;
  TextEditingController _promptController = TextEditingController();
  String? _imagePath;
  Map<String, dynamic>? _comparisonResults;
  bool _isLoading = false;

  List<String> _availableModels = []; // Will be fetched from API

  @override
  void initState() {
    super.initState();
    _fetchOllamaModels();
  }

  Future<void> _fetchOllamaModels() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    try {
      final models = await apiClient.getOllamaModels();
      if (mounted) {
        setState(() {
          _availableModels = models.map<String>((m) => m['name'] as String).toList();
          if (_availableModels.isNotEmpty) {
            _model1 = _availableModels.first;
            _model2 = _availableModels.length > 1 ? _availableModels[1] : null;
          }
        });
        telemetry.trackEvent('side_by_side_arena', 'fetch_models_success');
      }
    } catch (e) {
      telemetry.trackEvent('side_by_side_arena', 'fetch_models_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Ollama models: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('side_by_side_arena', 'pick_image_triggered');
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _imagePath = result.files.single.path;
      });
      telemetry.trackEvent('side_by_side_arena', 'image_picked', details: {'image_path': _imagePath});
    } else {
      telemetry.trackEvent('side_by_side_arena', 'image_pick_cancelled');
    }
  }

  Future<void> _compareModels() async {
    if (_model1 == null || _model2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請選擇兩個模型進行比較。')));
      return;
    }
    if (_promptController.text.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入提示詞或選擇圖片。')));
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
      _comparisonResults = null;
    });

    try {
      final results = await apiClient.compareModels(
        _model1!,
        _model2!,
        imagePath: _imagePath,
        prompt: _promptController.text.isNotEmpty ? _promptController.text : null,
      );
      if (mounted) {
        setState(() {
          _comparisonResults = results;
        });
        telemetry.trackEvent('side_by_side_arena', 'comparison_success', details: {'models': '${_model1} vs ${_model2}'});
      }
    } catch (e) {
      telemetry.trackEvent('side_by_side_arena', 'comparison_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模型比較失敗: $e')),
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
        title: const Text('模型競技場 (Side-by-Side Arena)'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('選擇模型進行比較 (Select Models for Comparison)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '模型 1 (Model 1)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                            value: _model1,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            items: _availableModels.map((String model) {
                              return DropdownMenuItem<String>(
                                value: model,
                                child: Text(model),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _model1 = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '模型 2 (Model 2)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                            value: _model2,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            items: _availableModels.map((String model) {
                              return DropdownMenuItem<String>(
                                value: model,
                                child: Text(model),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _model2 = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: '提示詞 (Prompt)',
                        hintText: '輸入文字提示...',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, color: Colors.white),
                            label: Text(_imagePath != null ? p.basename(_imagePath!) : '選擇圖片 (Pick Image)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_imagePath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _compareModels,
                        icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.compare),
                        label: Text(_isLoading ? '比較中...' : '開始比較 (Compare Models)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _comparisonResults == null
                  ? const Center(child: Text('點擊 "開始比較" 查看結果', style: TextStyle(color: Colors.white70)))
                  : Row(
                      children: [
                        Expanded(
                          child: ModelResponseCard(
                            modelName: _model1!,
                            response: _comparisonResults!['model1_response'],
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ModelResponseCard(
                            modelName: _model2!,
                            response: _comparisonResults!['model2_response'],
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModelResponseCard extends StatelessWidget {
  final String modelName;
  final Map<String, dynamic> response;
  final Color color;

  const ModelResponseCard({
    super.key,
    required this.modelName,
    required this.response,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final description = response['description'] ?? 'No description.';
    final confidence = response['confidence']?.toStringAsFixed(2) ?? 'N/A';
    final source = response['source'] ?? 'N/A';
    final error = response['error'];

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modelName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              )
            else ...[
              Text(
                '來源: $source',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '信心度: $confidence',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    description,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}