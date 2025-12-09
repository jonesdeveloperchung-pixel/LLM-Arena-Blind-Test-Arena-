import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ollama_benchmark_flutter/core/api_client.dart';
import 'package:ollama_benchmark_flutter/core/providers.dart';
import 'package:ollama_benchmark_flutter/core/telemetry.dart';
import 'dart:async';

import 'package:ollama_benchmark_flutter/features/pipeline/screens/alert_dashboard_screen.dart';

import 'alert_dashboard_screen_test.mocks.dart';

@GenerateMocks([ApiClient, TelemetryService])
void main() {
  group('AlertDashboardScreen Widget Tests', () {
    late MockApiClient mockApiClient;
    late MockTelemetryService mockTelemetryService;

    setUp(() {
      mockApiClient = MockApiClient();
      mockTelemetryService = MockTelemetryService();

      // Stub TelemetryService.log and trackEvent to prevent errors during tests
      when(mockTelemetryService.log(
        module: anyNamed('module'),
        action: anyNamed('action'),
        command: anyNamed('command'),
        executionMetrics: anyNamed('executionMetrics'),
        error: anyNamed('error'),
        context: anyNamed('context'),
        args: anyNamed('args'),
        tags: anyNamed('tags'),
      )).thenReturn(null);
      when(mockTelemetryService.trackEvent(
        any, // Positional module
        any, // Positional action
        details: anyNamed('details'), // Named argument
        error: anyNamed('error'),     // Named argument
      )).thenReturn(null);
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          telemetryServiceProvider.overrideWithValue(mockTelemetryService),
        ],
        child: const MaterialApp(
          home: AlertDashboardScreen(),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      final completer = Completer<List<dynamic>>();
      when(mockApiClient.get(any)).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(Duration.zero); // Trigger initial frame build

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]); // Complete with empty list to dismiss loading
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No alerts found matching current filters.'), findsOneWidget);
    });

    testWidgets('shows "No alerts found matching current filters." when API returns empty list', (WidgetTester tester) async {
      when(mockApiClient.get(any)).thenAnswer((_) async => Future.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('告警儀表板 (Alert Dashboard)'), findsOneWidget);
      expect(find.text('No alerts found matching current filters.'), findsOneWidget);
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_start', details: {'status_filter': 'active', 'severity_filter': 'all'})).called(1);
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_success', details: {'count': 0})).called(1);
    });

    testWidgets('displays list of alerts', (WidgetTester tester) async {
      when(mockApiClient.get(any)).thenAnswer((_) async => Future.value([
        {
          "id": 1,
          "timestamp": "2023-01-01T12:00:00.000Z",
          "source": "system",
          "message": "CPU usage critical",
          "severity": "critical",
          "details": {"cpu_percent": 95},
          "status": "active"
        },
        {
          "id": 2,
          "timestamp": "2023-01-01T12:05:00.000Z",
          "source": "pipeline",
          "message": "Model inference failed",
          "severity": "error",
          "details": {"model_name": "llama3", "error_code": 500},
          "status": "active"
        },
      ]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('告警儀表板 (Alert Dashboard)'), findsOneWidget);
      expect(find.text('system - CPU usage critical'), findsOneWidget);
      expect(find.text('Severity: CRITICAL'), findsOneWidget);
      expect(find.text('Status: ACTIVE'), findsNWidgets(2));
      expect(find.text('pipeline - Model inference failed'), findsOneWidget);
      expect(find.text('Severity: ERROR'), findsOneWidget);
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_success', details: {'count': 2})).called(1);

      // Clear telemetry and API interactions before filter change to only verify subsequent calls
      clearInteractions(mockTelemetryService);
      clearInteractions(mockApiClient);
    });

    testWidgets('shows error message when fetching alerts fails', (WidgetTester tester) async {
      final errorMessage = 'Failed to connect to backend';
      when(mockApiClient.get(any)).thenThrow(Exception(errorMessage));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('告警儀表板 (Alert Dashboard)'), findsOneWidget);
      expect(find.text('Failed to load alerts: Exception: $errorMessage'), findsNWidgets(2));
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_start', details: {'status_filter': 'active', 'severity_filter': 'all'})).called(1);
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_failure', error: 'Exception: $errorMessage')).called(1);
    });

    testWidgets('filters alerts by status', (WidgetTester tester) async {
      final activeAlerts = [
        {
          "id": 1,
          "timestamp": "2023-01-01T12:00:00.000Z",
          "source": "system",
          "message": "Active alert",
          "severity": "info",
          "status": "active"
        }
      ];
      final dismissedAlerts = [
        {
          "id": 2,
          "timestamp": "2023-01-01T12:05:00.000Z",
          "source": "pipeline",
          "message": "Dismissed alert",
          "severity": "warning",
          "status": "dismissed"
        }
      ];

      when(mockApiClient.get('/alerts?status=active')).thenAnswer((_) async => Future.value(activeAlerts));
      // Fetch for 'dismissed'
      when(mockApiClient.get('/alerts?status=dismissed')).thenAnswer((_) async => Future.value(dismissedAlerts));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('system - Active alert'), findsOneWidget);
      expect(find.text('Dismissed alert'), findsNothing); // Should not be present initially

      // Tap on the Status filter dropdown
      await tester.tap(find.text('ACTIVE')); // Find the current selected value
      await tester.pumpAndSettle();

      // Tap on 'DISMISSED' option
      await tester.tap(find.text('DISMISSED').last); // Use .last if there are multiple 'DISMISSED'
      await tester.pumpAndSettle();

      expect(find.text('system - Active alert'), findsNothing); // Active alert should be gone
      verify(mockApiClient.get('/alerts?status=dismissed')).called(1); // Verify mock was called
      expect(find.text('pipeline - Dismissed alert'), findsOneWidget);

      // Verify calls after filter change
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_start', details: {'status_filter': 'dismissed', 'severity_filter': 'all'})).called(1);
      verify(mockTelemetryService.trackEvent('alert_dashboard', 'fetch_alerts_success', details: {'count': 1})).called(1);
    });
  });
}
