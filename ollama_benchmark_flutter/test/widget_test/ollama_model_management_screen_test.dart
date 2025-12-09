import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ollama_benchmark_flutter/core/api_client.dart';
import 'package:ollama_benchmark_flutter/core/providers.dart';
import 'package:ollama_benchmark_flutter/core/telemetry.dart';
import 'dart:async'; // Import Completer
import 'package:ollama_benchmark_flutter/features/benchmark/screens/ollama_model_management_screen.dart';

// Import generated mocks for ApiClient and TelemetryService (after running build_runner)
import 'ollama_model_management_screen_test.mocks.dart';



@GenerateMocks([ApiClient, TelemetryService]) // Only generate mocks for ApiClient and TelemetryService
void main() {
  group('OllamaModelManagementScreen Widget Tests', () {
    late MockApiClient mockApiClient;
    late MockTelemetryService mockTelemetryService;

    setUp(() {
      mockApiClient = MockApiClient();
      mockTelemetryService = MockTelemetryService();

      // Stub TelemetryService.log to prevent errors during tests
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
      // Stub TelemetryService.trackEvent to prevent errors during tests
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
          home: OllamaModelManagementScreen(),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      final completer = Completer<List<dynamic>>(); // Create a Completer
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) => completer.future); // Mock to return the Completer's future

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(Duration.zero); // Pump the initial frame and subsequent frames caused by setState in initState
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // Now it should be found

      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_start')).called(1);
      
      completer.complete([]); // Resolve the Future with an empty list
      await tester.pumpAndSettle(); // Wait for the UI to update after future completion
      
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No Ollama models found. Is Ollama running?'), findsOneWidget);
      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_success')).called(1);
    });

    testWidgets('shows "No Ollama models found" when API returns empty list', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_start')).called(1);
      expect(find.text('Ollama Model Management'), findsOneWidget);
      expect(find.text('No Ollama models found. Is Ollama running?'), findsOneWidget);
      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_success')).called(1);
    });

    testWidgets('displays list of Ollama models', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([
        {'name': 'model1', 'model': 'model1:latest', 'size': 1073741824, 'modified_at': '2025-01-01T12:00:00Z'},
        {'name': 'model2', 'model': 'model2:latest', 'size': 2147483648, 'modified_at': '2025-01-02T12:00:00Z'},
      ]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_start')).called(1);
      expect(find.text('Ollama Model Management'), findsOneWidget); // Verify title
      expect(find.text('model1'), findsOneWidget);
      expect(find.text('Model: model1:latest'), findsOneWidget);
      expect(find.text('Size: 1.00 GB'), findsOneWidget);
      expect(find.text('model2'), findsOneWidget);
      expect(find.text('Size: 2.00 GB'), findsOneWidget);
      expect(find.text('Pull/Update'), findsNWidgets(2));
      expect(find.text('Delete'), findsNWidgets(2));
      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_success')).called(1);
    });

    testWidgets('pulls an existing model by tapping "Pull/Update" on its card', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([
        {'name': 'existing_model', 'model': 'existing_model:latest', 'size': 1, 'modified_at': 'now'},
      ]));
      when(mockApiClient.post('/ollama/pull', body: {'model_name': 'existing_model'}))
          .thenAnswer((_) async => {'message': 'Pulling model:existing_model'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('existing_model'), findsOneWidget);
      
      // Find the card for 'existing_model'
      final existingModelCard = find.ancestor(
        of: find.text('existing_model'),
        matching: find.byType(Card),
      );

      // Tap the "Pull/Update" button within the existing_model card
      await tester.tap(find.descendant(
        of: existingModelCard,
        matching: find.text('Pull/Update'),
      ));
      await tester.pumpAndSettle();

      verify(mockApiClient.post('/ollama/pull', body: {'model_name': 'existing_model'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'pull_model_start', details: {'model_name': 'existing_model'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'pull_model_success', details: {'model_name': 'existing_model'})).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Pulling existing_model... This may take a while.'), findsOneWidget);
    });

    testWidgets('pulls a new model via dialog', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([])); // Initial fetch for empty list
      // Mock ApiClient.post method, which takes path and body
      when(mockApiClient.post(any, body: anyNamed('body')))
          .thenAnswer((_) async => {'message': 'Pulling model:tag'}); 

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Wait for dialog to appear

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Pull Ollama Model'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'new_model:latest');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pull'));
      await tester.pumpAndSettle();

      verify(mockApiClient.post(any, body: {'model_name': 'new_model:latest'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'pull_model_start', details: {'model_name': 'new_model:latest'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'pull_model_success', details: {'model_name': 'new_model:latest'})).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Pulling new_model:latest... This may take a while.'), findsOneWidget);
    });

    testWidgets('does not pull model if name is empty in dialog', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([]));
      // Ensure post is never called
      when(mockApiClient.post(any, body: anyNamed('body'))).thenAnswer((_) async => {'message': 'Should not be called'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Wait for dialog

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Pull Ollama Model'), findsOneWidget);

      // Do not enter any text, leave it empty
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pull'));
      await tester.pumpAndSettle(); // Wait for dialog to close and potential SnackBar

      // Verify that the post method was never called with '/ollama/pull'
      verifyNever(mockApiClient.post('/ollama/pull', body: anyNamed('body')));
      expect(find.byType(SnackBar), findsNothing); // No SnackBar should appear

      // The dialog should be gone
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('deletes a model', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([
        {'name': 'modelToDelete', 'model': 'modelToDelete:latest', 'size': 1, 'modified_at': 'now'},
      ]));
      // Mock ApiClient.deleteOllamaModel method, which takes modelName (positional)
      when(mockApiClient.post('/ollama/delete', body: {'model_name': 'modelToDelete'}))
          .thenAnswer((_) async => {'message': 'Deleted'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('modelToDelete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(mockApiClient.post('/ollama/delete', body: {'model_name': 'modelToDelete'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'delete_model_start', details: {'model_name': 'modelToDelete'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'delete_model_success', details: {'model_name': 'modelToDelete'})).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Deleted modelToDelete.'), findsOneWidget);
    });

    testWidgets('shows error snackbar on fetch models failure', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenThrow(Exception('Failed to connect to Ollama'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Wait for Future to complete and SnackBar to appear

      verify(mockTelemetryService.trackEvent('ollama_management', 'fetch_models_start')).called(1);
      verify(mockTelemetryService.trackEvent(
        'ollama_management',
        'fetch_models_failure',
        error: 'Exception: Failed to connect to Ollama',
      )).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to load Ollama models: Exception: Failed to connect to Ollama'), findsOneWidget);
    });

    testWidgets('shows error snackbar on pull model failure', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([])); // Initial successful fetch
      when(mockApiClient.post(any, body: anyNamed('body')))
          .thenThrow(Exception('Pull failed'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Wait for dialog

      await tester.enterText(find.byType(TextField), 'fail_model');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pull'));
      await tester.pumpAndSettle(); // Wait for SnackBar to appear

      verify(mockTelemetryService.trackEvent('ollama_management', 'pull_model_start', details: {'model_name': 'fail_model'})).called(1);
      verify(mockTelemetryService.trackEvent(
        'ollama_management',
        'pull_model_failure',
        error: 'Exception: Pull failed',
      )).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to pull model fail_model: Exception: Pull failed'), findsOneWidget);
    });

    testWidgets('shows error snackbar on delete model failure', (WidgetTester tester) async {
      when(mockApiClient.get('/ollama/models')).thenAnswer((_) async => Future.value([
        {'name': 'modelToFail', 'model': 'modelToFail:latest', 'size': 1, 'modified_at': 'now'},
      ]));
      when(mockApiClient.post('/ollama/delete', body: {'model_name': 'modelToFail'}))
          .thenThrow(Exception('Delete failed'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle(); // Wait for SnackBar to appear

      verify(mockApiClient.post('/ollama/delete', body: {'model_name': 'modelToFail'})).called(1);
      verify(mockTelemetryService.trackEvent('ollama_management', 'delete_model_start', details: {'model_name': 'modelToFail'})).called(1);
      verify(mockTelemetryService.trackEvent(
        'ollama_management',
        'delete_model_failure',
        error: 'Exception: Delete failed',
      )).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to delete model modelToFail: Exception: Delete failed'), findsOneWidget);
    });


  });
}