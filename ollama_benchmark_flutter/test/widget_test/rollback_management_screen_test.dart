import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:async'; 
import 'package:ollama_benchmark_flutter/core/api_client.dart';
import 'package:ollama_benchmark_flutter/core/providers.dart';
import 'package:ollama_benchmark_flutter/core/telemetry.dart';
import 'package:ollama_benchmark_flutter/features/benchmark/screens/rollback_management_screen.dart';
import 'package:ollama_benchmark_flutter/features/benchmark/screens/rollback_management_screen.dart';

import 'rollback_management_screen_test.mocks.dart';

@GenerateMocks([ApiClient, TelemetryService])
void main() {
  group('RollbackManagementScreen Widget Tests', () {
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

      // Default stub for fetch backup files (can be overridden in specific tests)
      when(mockApiClient.get('/config/backups')).thenAnswer((_) async => Future.value([]));
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          telemetryServiceProvider.overrideWithValue(mockTelemetryService),
        ],
        child: const MaterialApp(
          home: RollbackManagementScreen(),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      final completer = Completer<List<dynamic>>();
      when(mockApiClient.get('/config/backups')).thenAnswer((_) => completer.future); // Override local stub

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Allow _fetchBackupFiles to be called and set _isLoading to true (first rebuild)
      await tester.pump(); // Allow the widget to rebuild with _isLoading = true (second rebuild)
      // At this point, initState has called _fetchBackupFiles, and it's awaiting the completer.
      // The ScaffoldMessenger error should not occur.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      expect(find.text('Rollback Management'), findsOneWidget);

      // Now complete the future so the data can be processed
      completer.complete([]);
      await tester.pumpAndSettle();

      // Verify that the loading indicator is gone and no error message is displayed
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Failed to load backup files:'), findsNothing);
    });

    testWidgets('displays "No backup files found." when API returns empty list', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Settle all frames

      expect(find.text('Rollback Management'), findsOneWidget);
      expect(find.text('No backup files found.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Failed to load backup files:'), findsNothing);
    });

    testWidgets('displays a list of backup files', (WidgetTester tester) async {
      final completer = Completer<List<dynamic>>();
      final backupFiles = ['backup_1.zip', 'backup_2.zip', 'backup_3.zip'];
      when(mockApiClient.get('/config/backups')).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Show loading indicator
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(backupFiles); // Complete with data
      await tester.pumpAndSettle(); // Settle all frames

      expect(find.text('Rollback Management'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No backup files found.'), findsNothing);

      for (var filename in backupFiles) {
        expect(find.text(filename), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Restore'), findsWidgets); // Each item should have a restore button
      }
    });

    testWidgets('shows error message when fetching backup files fails', (WidgetTester tester) async {
      final completer = Completer<List<dynamic>>();
      final errorMessage = 'Failed to connect to backend';
      when(mockApiClient.get('/config/backups')).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Show loading indicator
      await tester.pump(); // Ensure rebuild to show loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.completeError(Exception(errorMessage)); // Complete with an error
      await tester.pumpAndSettle(); // Settle all frames

      expect(find.text('Rollback Management'), findsOneWidget);
      expect(find.text('Failed to load backup files: Exception: $errorMessage'), findsNWidgets(2)); // Error message shown in body and snackbar
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No backup files found.'), findsNothing);
    });

    testWidgets('shows rollback confirmation dialog', (WidgetTester tester) async {
      final backupFiles = ['backup_latest.zip'];
      when(mockApiClient.get('/config/backups')).thenAnswer((_) async => Future.value(backupFiles));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Settle all frames and display backup files

      expect(find.text('Rollback Management'), findsOneWidget);
      expect(find.text('backup_latest.zip'), findsOneWidget);

      // Tap the Restore button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Restore'));
      await tester.pumpAndSettle(); // Allow dialog to appear

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Confirm Rollback'), findsOneWidget);
      expect(find.text('Are you sure you want to restore the configuration from "backup_latest.zip"? This action cannot be undone.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Restore')), findsOneWidget);
    });

    testWidgets('calls _performRollback when "Restore" is confirmed in dialog', (WidgetTester tester) async {
      final backupFiles = ['backup_latest.zip'];
      when(mockApiClient.get('/config/backups')).thenAnswer((_) async => Future.value(backupFiles));
      when(mockApiClient.post('/config/rollback')).thenAnswer((_) async => Future.value(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Settle all frames and display backup files

      expect(find.text('Rollback Management'), findsOneWidget);
      expect(find.text('backup_latest.zip'), findsOneWidget);

      // Tap the Restore button for the backup file
      await tester.tap(find.widgetWithText(ElevatedButton, 'Restore'));
      await tester.pumpAndSettle(); // Allow dialog to appear

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap the Restore button inside the dialog
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Restore')));
      verify(mockApiClient.post('/config/rollback')).called(1);
    });

    testWidgets('calls _fetchBackupFiles to refresh list after successful rollback', (WidgetTester tester) async {
      final initialBackupFiles = ['backup_latest.zip']; // Changed to backup_latest.zip
      final refreshedBackupFiles = ['backup_latest.zip', 'backup_new.zip'];
      
      // Stub initial fetch (resolved immediately for initial render)
      when(mockApiClient.get('/config/backups'))
          .thenAnswer((_) async => Future.value(initialBackupFiles));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Settle initial fetch and display files

      expect(find.text('backup_latest.zip'), findsOneWidget); // Changed
      clearInteractions(mockApiClient); // Clear calls from initial fetch

      // Stub post and subsequent fetch
      when(mockApiClient.post('/config/rollback')).thenAnswer((_) async => Future.value(null));
      when(mockApiClient.get('/config/backups'))
          .thenAnswer((_) async => Future.value(refreshedBackupFiles)); // This will be called for refresh

      // Tap the Restore button for the backup file
      await tester.tap(find.widgetWithText(ElevatedButton, 'Restore'));
      await tester.pumpAndSettle(); // Allow dialog to appear

      // Tap the Restore button inside the dialog
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ElevatedButton, 'Restore')));
      await tester.pumpAndSettle(); // Allow rollback operation to complete and dialog to dismiss

      // Verify that post('/config/rollback') was called
      verify(mockApiClient.post('/config/rollback')).called(1);
      
      // Verify that _fetchBackupFiles was called to refresh the list (which makes a get request)
      verify(mockApiClient.get('/config/backups')).called(1);
      
      // Verify telemetry events
      verify(mockTelemetryService.trackEvent('rollback_management', 'rollback_success', details: {'filename': 'backup_latest.zip'})).called(1); // Changed
      verify(mockTelemetryService.trackEvent('rollback_management', 'fetch_backups_start')).called(1);
      verify(mockTelemetryService.trackEvent('rollback_management', 'fetch_backups_success', details: {'count': 2})).called(1);
      
      expect(find.text('backup_new.zip'), findsOneWidget); // Verify new file is displayed
    });
  });
}