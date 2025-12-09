import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

import '../../../core/providers.dart';
import '../../../core/telemetry.dart';

class BlindTestArenaScreen extends ConsumerStatefulWidget {
  const BlindTestArenaScreen({super.key});

  @override
  ConsumerState<BlindTestArenaScreen> createState() => _BlindTestArenaScreenState();
}

class _BlindTestArenaScreenState extends ConsumerState<BlindTestArenaScreen> {
  Map<String, dynamic>? _blindTestPrompt;
  bool _isLoading = false;
  String? _selectedPreference;
  String? _modelAId; // Stored from backend response
  String? _modelBId; // Stored from backend response
  String? _promptOrImageRef; // Stored from backend response

  @override
  void initState() {
    super.initState();
    _fetchBlindTestPrompt();
  }

  Future<void> _fetchBlindTestPrompt() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
      _blindTestPrompt = null;
      _selectedPreference = null;
    });

    try {
      // Exclude models that are not vision models if we are presenting an image.
      // For MVP, we fetch any two models for text-based comparison.
      final prompt = await apiClient.getBlindTestPrompt();
      if (mounted) {
        setState(() {
          _blindTestPrompt = prompt;
          _modelAId = prompt['model_a_id'];
          _modelBId = prompt['model_b_id'];
          _promptOrImageRef = prompt['prompt_content'] ?? prompt['prompt_text'];
        });
        telemetry.trackEvent('blind_test', 'fetch_prompt_success');
      }
    } catch (e) {
      telemetry.trackEvent('blind_test', 'fetch_prompt_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('獲取盲測提示失敗: $e')),
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

  Future<void> _submitPreference() async {
    if (_selectedPreference == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請選擇您的偏好。')));
      return;
    }
    if (_modelAId == null || _modelBId == null || _promptOrImageRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法提交，缺少必要信息。')));
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiClient.submitBlindTestResult(
        _modelAId!,
        _modelBId!,
        _selectedPreference!,
        _promptOrImageRef!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('偏好已提交: ${response['message']}')),
        );
        telemetry.trackEvent('blind_test', 'submit_preference_success', details: {'preference': _selectedPreference});
        _fetchBlindTestPrompt(); // Fetch a new prompt after submission
      }
    } catch (e) {
      telemetry.trackEvent('blind_test', 'submit_preference_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交偏好失敗: $e')),
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
        title: const Text('盲測競技場 (Blind Test Arena)'),
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
                    const Text('測試提示 (Test Prompt)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_blindTestPrompt != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_blindTestPrompt!['prompt_content'] != null && _blindTestPrompt!['prompt_content'].endsWith('.jpg'))
                            // Display image if it's an image path
                            // Note: For web/desktop, direct file access might need universal_io or specific platform channels.
                            // For MVP, if it's a local file path, we'll just show the path for now or a placeholder.
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '圖像路徑: ${p.basename(_blindTestPrompt!['prompt_content'])}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            )
                          else
                            // Display text prompt
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _blindTestPrompt!['prompt_text'] ?? 'No text prompt provided.',
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Text('模型回應 (Model Responses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ModelResponseDisplay(
                                  label: '回應 A',
                                  response: _blindTestPrompt!['response_a'],
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ModelResponseDisplay(
                                  label: '回應 B',
                                  response: _blindTestPrompt!['response_b'],
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ToggleButtons(
                              isSelected: [
                                _selectedPreference == 'A',
                                _selectedPreference == 'B',
                                _selectedPreference == 'tie',
                              ],
                              onPressed: (int index) {
                                setState(() {
                                  if (index == 0) _selectedPreference = 'A';
                                  if (index == 1) _selectedPreference = 'B';
                                  if (index == 2) _selectedPreference = 'tie';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.white,
                              fillColor: const Color(0xFF10B981),
                              borderColor: Colors.white30,
                              selectedBorderColor: const Color(0xFF34D399),
                              children: const [
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('偏好 A', style: TextStyle(color: Colors.white))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('偏好 B', style: TextStyle(color: Colors.white))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('平局 (Tie)', style: TextStyle(color: Colors.white))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || _selectedPreference == null ? null : _submitPreference,
                              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.send),
                              label: Text(_isLoading ? '提交中...' : '提交偏好並獲取下一個 (Submit)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Center(child: Text('沒有盲測提示 (No blind test prompts available)', style: TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModelResponseDisplay extends StatelessWidget {
  final String label;
  final String response;
  final Color color;

  const ModelResponseDisplay({
    super.key,
    required this.label,
    required this.response,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              response,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}