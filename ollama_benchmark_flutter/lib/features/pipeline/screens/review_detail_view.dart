import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert'; // For jsonDecode
import '../../../core/providers.dart'; // For apiClientProvider and telemetryServiceProvider

class ReviewDetailView extends ConsumerStatefulWidget {
  final String itemId;

  const ReviewDetailView({super.key, required this.itemId});

  @override
  ConsumerState<ReviewDetailView> createState() => _ReviewDetailViewState();
}

class _ReviewDetailViewState extends ConsumerState<ReviewDetailView> {
  Map<String, dynamic>? _itemDetails;
  bool _isLoading = true;
  TextEditingController _descriptionController = TextEditingController();
  String _currentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  Future<void> _fetchItemDetails() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
    });
    try {
      final details = await apiClient.getPipelineItem(widget.itemId);
      if (mounted) {
        setState(() {
          _itemDetails = details;
          _descriptionController.text = _itemDetails!['description'] ?? '';
          _currentStatus = _itemDetails!['status'] ?? 'pending';
        });
        telemetry.trackEvent('review_detail', 'fetch_item_success', details: {'item_id': widget.itemId});
      }
    } catch (e) {
      telemetry.trackEvent('review_detail', 'fetch_item_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load item details: $e')),
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

  Future<void> _updateItemStatus(String status) async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiClient.updatePipelineItem(
        widget.itemId,
        description: _descriptionController.text,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item updated: ${response['message']}')),
        );
        telemetry.trackEvent('review_detail', 'update_item_success', details: {'item_id': widget.itemId, 'status': status});
        Navigator.pop(context, true); // Pop and indicate success to refresh previous screen
      }
    } catch (e) {
      telemetry.trackEvent('review_detail', 'update_item_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_itemDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Could not load item details.')),
      );
    }

    // Access raw_response to extract more details if needed
    final rawMetadata = _itemDetails!['metadata_json'] != null 
        ? jsonDecode(_itemDetails!['metadata_json']) : {};
    
    // Display image from local filepath if possible, otherwise placeholder
    final imagePath = rawMetadata['original_filepath'] ?? ''; // Assuming filepath is in metadata
    Widget imageWidget = Container(
      width: 200,
      height: 200,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 100, color: Colors.grey),
    );
    // Note: Displaying local file paths directly in Flutter for web/desktop
    // can be complex. For MVP, just show placeholder or file name.
    // Image.file(File(imagePath)) won't work cross-platform easily.

    return Scaffold(
      appBar: AppBar(
        title: Text('審核項目: ${_itemDetails!['filename']}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: imageWidget, // Placeholder image
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('檔名: ${_itemDetails!['filename']}', style: Theme.of(context).textTheme.titleLarge),
                    Text('狀態: $_currentStatus', style: Theme.of(context).textTheme.titleMedium),
                    Text('來源: ${_itemDetails!['source'] ?? 'N/A'}'),
                    Text('信心度: ${_itemDetails!['confidence_score']?.toStringAsFixed(2) ?? 'N/A'}'),
                    Text('處理時間: ${_itemDetails!['processing_time_ms'] ?? 'N/A'} ms'),
                    Text('建立於: ${_itemDetails!['created_at']}'),
                    Text('更新於: ${_itemDetails!['updated_at']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('描述 (Description)', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '編輯描述...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateItemStatus('approved'),
                  icon: const Icon(Icons.check),
                  label: const Text('批准 (Approve)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateItemStatus('rejected'),
                  icon: const Icon(Icons.close),
                  label: const Text('駁回 (Reject)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
