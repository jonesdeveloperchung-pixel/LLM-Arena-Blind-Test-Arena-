import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'dart:typed_data'; // Import for Uint8List
import '../../../core/providers.dart';
import '../../../core/telemetry.dart';
import 'package:file_saver/file_saver.dart'; // For downloading files

class ReportExportScreen extends ConsumerStatefulWidget {
  const ReportExportScreen({super.key});

  @override
  ConsumerState<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends ConsumerState<ReportExportScreen> {
  String? _selectedCategory;
  String? _selectedModel; // This would ideally come from a list of models used in benchmarks
  DateTime? _startDate;
  DateTime? _endDate;
  String _generatedReportContent = '';
  bool _isLoading = false;

  // Placeholder for available categories and models - would be dynamic in a real app
  final List<String> _availableCategories = ['Reasoning', 'Coding', 'Vision', 'Language', 'Embedding'];
  final List<String> _availableModels = ['Llama 3.2', 'Llama 2', 'Mistral']; // Example models

  @override
  void initState() {
    super.initState();
    // Initialize with first category as default
    if (_availableCategories.isNotEmpty) {
      _selectedCategory = _availableCategories.first;
    }
  }

  Future<void> _generateReport() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
      _generatedReportContent = '';
    });

    try {
      final report = await apiClient.generateBenchmarkReport(
        _selectedCategory ?? 'all', // Default to 'all' if no category selected
        model: _selectedModel,
        startDate: _startDate?.toIso8601String().split('T').first,
        endDate: _endDate?.toIso8601String().split('T').first,
      );
      if (mounted) {
        setState(() {
          _generatedReportContent = report;
        });
        telemetry.trackEvent('report_export', 'generate_report_success');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報告已生成!')));
      }
    } catch (e) {
      telemetry.trackEvent('report_export', 'generate_report_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成報告失敗: $e')),
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

  Future<void> _downloadReport() async {
    if (_generatedReportContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先生成報告!')));
      return;
    }
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('report_export', 'download_report_triggered');

    try {
      final fileName = 'benchmark_report_${_selectedCategory ?? 'all'}_${DateTime.now().millisecondsSinceEpoch}.md';
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(_generatedReportContent.codeUnits),
        ext: 'md',
        mimeType: MimeType.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報告已下載!')));
      telemetry.trackEvent('report_export', 'download_report_success');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下載報告失敗: $e')),
      );
      telemetry.trackEvent('report_export', 'download_report_failure', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生成報告 (Generate Report)'),
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F172A), // Slate 950
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Options
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('篩選器 (Filters)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '類別 (Category)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: _availableCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '模型 (Model)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      value: _selectedModel,
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
                          _selectedModel = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != _startDate) {
                                setState(() {
                                  _startDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '開始日期 (Start Date)',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              child: Text(
                                _startDate == null ? '選擇日期' : DateFormat('yyyy-MM-dd').format(_startDate!),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != _endDate) {
                                setState(() {
                                  _endDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '結束日期 (End Date)',
                                labelStyle: TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                              child: Text(
                                _endDate == null ? '選擇日期' : DateFormat('yyyy-MM-dd').format(_endDate!),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateReport,
                          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.description),
                          label: Text(_isLoading ? '生成中...' : '生成報告 (Generate)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Emerald 500
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generatedReportContent.isEmpty ? null : _downloadReport,
                          icon: const Icon(Icons.download),
                          label: const Text('下載報告 (Download)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Report Preview
            Expanded(
              child: Card(
                color: const Color(0xFF1E293B),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _generatedReportContent.isEmpty ? '點擊 "生成報告" 以預覽結果' : _generatedReportContent,
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}