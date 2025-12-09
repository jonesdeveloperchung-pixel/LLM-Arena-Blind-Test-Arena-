import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ollama_benchmark_flutter/core/api_client.dart';
import 'package:ollama_benchmark_flutter/core/telemetry.dart'; // Import TelemetryService
import 'dart:convert'; // Import for jsonEncode

import 'api_client_ollama_management_test.mocks.dart'; // Generated mock file

@GenerateMocks([http.Client, TelemetryService]) // Generate mock for TelemetryService as well
void main() {
  group('ApiClient Ollama Management Tests', () {
    late MockClient mockClient;
    late MockTelemetryService mockTelemetryService; // Declare mock TelemetryService
    late ApiClient apiClient;

    setUp(() {
      mockClient = MockClient();
      mockTelemetryService = MockTelemetryService(); // Instantiate mock TelemetryService
      apiClient = ApiClient(httpClient: mockClient, telemetryService: mockTelemetryService); // Inject both mocks

      // Stub the log method of TelemetryService to prevent actual calls and errors during tests
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
    });

    test('get /ollama/models returns a list of models on success', () async {
      when(mockClient.get(Uri.parse('http://localhost:8000/ollama/models'), headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          '[{"name": "model1", "model": "model1:latest", "size": 1000, "digest": "abc", "modified_at": "now"}, {"name": "model2", "model": "model2:latest", "size": 2000, "digest": "def", "modified_at": "then"}]',
          200,
        ),
      );

      final models = await apiClient.getOllamaModels(); // Use the specific method
      expect(models, isA<List>());
      expect(models.length, 2);
      expect(models[0]['name'], 'model1');
      expect(models[1]['name'], 'model2');
    });

    test('get /ollama/models returns empty list if no models', () async {
      when(mockClient.get(Uri.parse('http://localhost:8000/ollama/models'), headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('[]', 200),
      );

      final models = await apiClient.getOllamaModels();
      expect(models, isA<List>());
      expect(models, []);
    });

    test('get /ollama/models throws exception on non-200 response', () async {
      when(mockClient.get(Uri.parse('http://localhost:8000/ollama/models'), headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('Server error', 500),
      );

      expect(() => apiClient.getOllamaModels(), throwsA(isA<Exception>()));
    });

    test('pullOllamaModel returns success message on success', () async {
      final requestBody = jsonEncode({'model_name': 'model1:latest'});
      when(mockClient.post(
        Uri.parse('http://localhost:8000/ollama/pull'), // Explicit Uri
        headers: anyNamed('headers'),
        body: requestBody, // Explicit body
      )).thenAnswer(
        (_) async => http.Response('{"message": "Pulling model1:latest"}', 200),
      );

      final response = await apiClient.pullOllamaModel('model1:latest');
      expect(response, isA<Map<String, dynamic>>());
      expect(response['message'], 'Pulling model1:latest');
    });

    test('pullOllamaModel throws exception on non-200 response', () async {
      final requestBody = jsonEncode({'model_name': 'model1:latest'});
      when(mockClient.post(
        Uri.parse('http://localhost:8000/ollama/pull'), // Explicit Uri
        headers: anyNamed('headers'),
        body: requestBody, // Explicit body
      )).thenAnswer(
        (_) async => http.Response('Not Implemented', 501),
      );

      expect(() => apiClient.pullOllamaModel('model1:latest'), throwsA(isA<Exception>()));
    });

    test('deleteOllamaModel returns success message on success', () async {
      final uri = Uri.parse('http://localhost:8000/ollama/delete/model1:latest');
      when(mockClient.delete(
        uri, // Explicit Uri
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('{"message": "Deleted model1:latest"}', 200),
      );

      final response = await apiClient.deleteOllamaModel('model1:latest');
      expect(response, isA<Map<String, dynamic>>());
      expect(response['message'], 'Deleted model1:latest');
    });

    test('deleteOllamaModel throws exception on non-200 response', () async {
      final uri = Uri.parse('http://localhost:8000/ollama/delete/model1:latest');
      when(mockClient.delete(
        uri, // Explicit Uri
        headers: anyNamed('headers'),
      )).thenAnswer(
        (_) async => http.Response('Not Implemented', 501),
      );

      expect(() => apiClient.deleteOllamaModel('model1:latest'), throwsA(isA<Exception>()));
    });

    group('getSystemResources', () {
      test('returns CPU and RAM usage on success', () async {
        when(mockClient.get(Uri.parse('http://localhost:8000/monitoring/resources'), headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response(
            '{"cpu_percent": 25.5, "ram_percent": 50.2}',
            200,
          ),
        );

        final resources = await apiClient.getSystemResources();
        expect(resources, isA<Map<String, dynamic>>());
        expect(resources['cpu_percent'], 25.5);
        expect(resources['ram_percent'], 50.2);
      });

      test('throws exception on non-200 response', () async {
        when(mockClient.get(Uri.parse('http://localhost:8000/monitoring/resources'), headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Server error', 500),
        );

        expect(() => apiClient.getSystemResources(), throwsA(isA<Exception>()));
      });

      test('throws exception on invalid response format', () async {
        when(mockClient.get(Uri.parse('http://localhost:8000/monitoring/resources'), headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('{"not_a_map": []}', 200), // Invalid format
        );

        expect(() => apiClient.getSystemResources(), throwsA(isA<Exception>()));
      });
    });

    group('getTelemetryLogs', () {
      test('returns a list of telemetry logs on success', () async {
        final expectedUri = Uri.parse('http://localhost:8000/telemetry/logs');
        when(mockClient.get(expectedUri, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response(
            '[{"timestamp": "2023-01-01T00:00:00Z", "program": "app", "version": "1.0.0", "action": "test", "user": "user", "host": "host", "os": "os", "runtime": "dart"}]',
            200,
          ),
        );

        final logs = await apiClient.getTelemetryLogs();
        expect(logs, isA<List>());
        expect(logs.length, 1);
        expect(logs[0]['action'], 'test');
      });

      test('returns an empty list if no logs', () async {
        final expectedUri = Uri.parse('http://localhost:8000/telemetry/logs');
        when(mockClient.get(expectedUri, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('[]', 200),
        );

        final logs = await apiClient.getTelemetryLogs();
        expect(logs, isA<List>());
        expect(logs, []);
      });

      test('throws exception on non-200 response', () async {
        final expectedUri = Uri.parse('http://localhost:8000/telemetry/logs');
        when(mockClient.get(expectedUri, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('Server error', 500),
        );

        expect(() => apiClient.getTelemetryLogs(), throwsA(isA<Exception>()));
      });

      test('throws exception on invalid response format', () async {
        final expectedUri = Uri.parse('http://localhost:8000/telemetry/logs');
        when(mockClient.get(expectedUri, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('{"not_a_list": {}}', 200), // Invalid format
        );

        expect(() => apiClient.getTelemetryLogs(), throwsA(isA<Exception>()));
      });

      test('passes filter parameters correctly', () async {
        final expectedUri = Uri.parse('http://localhost:8000/telemetry/logs?program=test_program&module=test_module&limit=10');
        when(mockClient.get(expectedUri, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response('[]', 200),
        );

        await apiClient.getTelemetryLogs(program: 'test_program', module: 'test_module', limit: 10);
        verify(mockClient.get(expectedUri, headers: anyNamed('headers'))).called(1);
      });
    });
  });
}