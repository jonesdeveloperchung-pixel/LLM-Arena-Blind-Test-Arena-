import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:llm_arena_blind_test_arena/core/providers.dart';
import 'package:llm_arena_blind_test_arena/core/telemetry.dart';
import 'package:llm_arena_blind_test_arena/core/models/alert_model.dart'; // Import the new Alert model

class AlertDashboardScreen extends ConsumerStatefulWidget {
  const AlertDashboardScreen({super.key});

  @override
  ConsumerState<AlertDashboardScreen> createState() => _AlertDashboardScreenState();
}

class _AlertDashboardScreenState extends ConsumerState<AlertDashboardScreen> {
  bool _isLoading = false;
  List<Alert> _alerts = [];
  String? _errorMessage;
  String _selectedStatusFilter = 'active'; // Filter by active, dismissed, all
  String _selectedSeverityFilter = 'all'; // Filter by info, warning, error, critical, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAlerts();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) { // Ensure widget is still in tree
      // Access context only if widget is mounted and after build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Re-check mounted after frame callback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: TextStyle(color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onTertiary)),
              backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchAlerts() async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('alert_dashboard', 'fetch_alerts_start', details: {'status_filter': _selectedStatusFilter, 'severity_filter': _selectedSeverityFilter});
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final Map<String, dynamic> queryParams = {};
      if (_selectedStatusFilter != 'all') {
        queryParams['status'] = _selectedStatusFilter;
      }
      if (_selectedSeverityFilter != 'all') {
        queryParams['severity'] = _selectedSeverityFilter;
      }
      
      final uri = Uri.parse('/alerts').replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      final response = await apiClient.get(uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
      if (mounted) {
        setState(() {
          _alerts = (response as List).map((e) => Alert.fromJson(e)).toList();
          _isLoading = false;
          // Clear any previous error message if data is successfully loaded
          _errorMessage = null; 
        });
        telemetry.trackEvent('alert_dashboard', 'fetch_alerts_success', details: {'count': _alerts.length});
      }
    } catch (e) {
      telemetry.trackEvent('alert_dashboard', 'fetch_alerts_failure', error: e.toString());
      if (mounted) {
        setState(() {
          // Only show persistent error message if there are no alerts to display
          if (_alerts.isEmpty) {
            _errorMessage = 'Failed to load alerts: $e';
          }
          _isLoading = false;
        });
        _showSnackBar('Failed to load alerts: $e', isError: true);
      }
    }
  }

  Future<void> _dismissAlert(int alertId) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('alert_dashboard', 'dismiss_alert_start', details: {'alert_id': alertId});
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/alerts/$alertId/dismiss');
      if (mounted) {
        _showSnackBar('Alert $alertId dismissed successfully.');
        telemetry.trackEvent('alert_dashboard', 'dismiss_alert_success', details: {'alert_id': alertId});
        _fetchAlerts(); // Refresh list
      }
    } catch (e) {
      telemetry.trackEvent('alert_dashboard', 'dismiss_alert_failure', error: e.toString());
      if (mounted) {
        _showSnackBar('Failed to dismiss alert $alertId: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resolveAlert(int alertId) async {
    final telemetry = ref.read(telemetryServiceProvider);
    telemetry.trackEvent('alert_dashboard', 'resolve_alert_start', details: {'alert_id': alertId});
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/alerts/$alertId/resolve');
      if (mounted) {
        _showSnackBar('Alert $alertId resolved successfully.');
        telemetry.trackEvent('alert_dashboard', 'resolve_alert_success', details: {'alert_id': alertId});
        _fetchAlerts(); // Refresh list
      }
    } catch (e) {
      telemetry.trackEvent('alert_dashboard', 'resolve_alert_failure', error: e.toString());
      if (mounted) {
        _showSnackBar('Failed to resolve alert $alertId: $e', isError: true);
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
        title: const Text('告警儀表板 (Alert Dashboard)'),
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAlerts,
          ),
          _buildFilterDropdown('Status', _selectedStatusFilter, ['all', 'active', 'dismissed', 'resolved'], (newValue) {
            setState(() {
              _selectedStatusFilter = newValue!;
            });
            _fetchAlerts();
          }),
          _buildFilterDropdown('Severity', _selectedSeverityFilter, ['all', 'info', 'warning', 'error', 'critical'], (newValue) {
            setState(() {
              _selectedSeverityFilter = newValue!;
            });
            _fetchAlerts();
          }),
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
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _alerts.isEmpty
                  ? const Center(
                      child: Text(
                        'No alerts found matching current filters.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final Color severityColor = _getSeverityColor(alert.severity);
                        final String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(alert.timestamp);

                        return Card(
                          color: const Color(0xFF1E293B), // Slate 800
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ExpansionTile(
                            leading: Icon(_getSeverityIcon(alert.severity), color: severityColor),
                            title: Text(
                              '${alert.source} - ${alert.message}',
                              style: TextStyle(color: severityColor, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Severity: ${alert.severity.toUpperCase()}', style: TextStyle(color: Colors.white70)),
                                Text('Status: ${alert.status.toUpperCase()}', style: TextStyle(color: Colors.white70)),
                                Text('Time: $formattedTimestamp', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Details:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(alert.details?.toString() ?? 'N/A', style: TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (alert.status == 'active') ...[
                                          ElevatedButton(
                                            onPressed: _isLoading ? null : () => _dismissAlert(alert.id),
                                            child: const Text('Dismiss'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _isLoading ? null : () => _resolveAlert(alert.id),
                                            child: const Text('Resolve'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.filter_list, color: Colors.white70),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase(), style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'critical':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'critical':
        return Icons.dangerous_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}
