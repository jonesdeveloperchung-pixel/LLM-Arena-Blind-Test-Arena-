import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:llm_arena_blind_test_arena/core/telemetry.dart';

class ApiClient {
  final String baseUrl;
  final TelemetryService _telemetry;
  final http.Client _httpClient;

  ApiClient({
    this.baseUrl = 'http://localhost:8000',
    http.Client? httpClient,
    TelemetryService? telemetryService,
  })  : _httpClient = httpClient ?? http.Client(),
        _telemetry = telemetryService ?? TelemetryService();

  Future<dynamic> _get(String path, {bool allow_404_null = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final start = DateTime.now();
    try {
      final response = await _httpClient.get(uri);
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_get',
        command: 'GET $path',
        executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404 && allow_404_null) {
        _telemetry.log(
          module: 'api_client',
          action: 'http_get_404_as_null',
          command: 'GET $path',
          executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
        );
        return null; // Return null for 404 if allowed
      }
      else {
        _telemetry.log(
          module: 'api_client',
          action: 'http_get_error',
          command: 'GET $path',
          executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
          error: response.body,
        );
        throw Exception('Failed to load data from $path: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_get_exception',
        command: 'GET $path',
        executionMetrics: {'duration_ms': duration_ms},
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final start = DateTime.now();
    try {
      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body != null ? json.encode(body) : null,
      );
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_post',
        command: 'POST $path',
        executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        _telemetry.log(
          module: 'api_client',
          action: 'http_post_error',
          command: 'POST $path',
          executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
          error: response.body,
        );
        throw Exception('Failed to post data to $path: ${response.statusCode} - ${response.body}');
      }
    }
    catch (e) {
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_post_exception',
        command: 'POST $path',
        executionMetrics: {'duration_ms': duration_ms},
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<dynamic> get(String path) async {
    return await _get(path);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    return await _post(path, body: body);
  }

  Future<bool> checkOllamaHealth() async {
    try {
      final response = await _get('/ollama/health');
      return response['status'] == 'healthy';
    } catch (e) {
      debugPrint('Ollama health check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> runPipeline() async {
    return await _post('/pipeline/run');
  }

  Future<Map<String, dynamic>> runBenchmark(String category, String model, String prompt, {String? language}) async {
    final body = <String, dynamic>{
      'category': category,
      'model': model,
      'prompt': prompt,
    };
    if (language != null) body['language'] = language;
    return await _post('/benchmark/run', body: body);
  }

  Future<Map<String, dynamic>> getPipelineStatus() async {
    return await _get('/pipeline/status');
  }

  Future<Map<String, dynamic>?> getBenchmarkResults(String category) async {
    try {
      return await _get('/benchmark/results/${category.toLowerCase()}', allow_404_null: true);
    } catch (e) {
      // If there's any other exception, rethrow it
      rethrow;
    }
  }

  // Pipeline Item Management
  Future<List<dynamic>> getPipelineItems() async {
    final response = await _get('/pipeline/items');
    if (response is List) {
      return response;
    }
    throw Exception('Unexpected API response format for /pipeline/items: $response');
  }

  Future<Map<String, dynamic>> getPipelineItem(String itemId) async {
    return await _get('/pipeline/items/$itemId');
  }

  Future<Map<String, dynamic>> updatePipelineItem(String itemId, {String? description, String? status}) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    return await _post('/pipeline/items/$itemId/update', body: body);
  }

  // Ollama Model Management
  Future<List<dynamic>> getOllamaModels() async {
    final response = await _get('/ollama/models');
    if (response is List) {
      return response;
    }
    throw Exception('Unexpected API response format for /ollama/models: $response');
  }

  Future<Map<String, dynamic>> pullOllamaModel(String modelName) async {
    return await _post('/ollama/pull', body: {'model_name': modelName});
  }

  Future<Map<String, dynamic>> deleteOllamaModel(String modelName) async {
    return await _delete('/ollama/delete/$modelName');
  }
  
  // Need to add a _delete method for consistency
  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final start = DateTime.now();
    try {
      final response = await _httpClient.delete(uri, headers: {'Content-Type': 'application/json'}); // Add headers for consistency
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_delete',
        command: 'DELETE $path',
        executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        _telemetry.log(
          module: 'api_client',
          action: 'http_delete_error',
          command: 'DELETE $path',
          executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
          error: response.body,
        );
        throw Exception('Failed to delete data from $path: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_delete_exception',
        command: 'DELETE $path',
        executionMetrics: {'duration_ms': duration_ms},
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<List<dynamic>> getBenchmarkHistory(String category) async {
    final response = await _get('/benchmark/history/${category.toLowerCase()}');
    if (response is List) {
      return response;
    }
    throw Exception('Unexpected API response format for /benchmark/history: $response');
  }

  Future<String> generateBenchmarkReport(String category, {String? model, String? startDate, String? endDate}) async {
    final Map<String, dynamic> queryParams = {
      'category': category.toLowerCase(),
    };
    if (model != null) queryParams['model'] = model;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/benchmark/report').replace(queryParameters: queryParams);
    final start = DateTime.now();
    try {
      final response = await http.get(uri);
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_get_report',
        command: 'GET /benchmark/report',
        executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
      );

      if (response.statusCode == 200) {
        return response.body; // Expecting plain text Markdown
      } else {
        _telemetry.log(
          module: 'api_client',
          action: 'http_get_report_error',
          command: 'GET /benchmark/report',
          executionMetrics: {'duration_ms': duration_ms, 'status_code': response.statusCode},
          error: response.body,
        );
        throw Exception('Failed to generate report: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final duration_ms = DateTime.now().difference(start).inMilliseconds;
      _telemetry.log(
        module: 'api_client',
        action: 'http_get_report_exception',
        command: 'GET /benchmark/report',
        executionMetrics: {'duration_ms': duration_ms},
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> compareModels(String model1, String model2, {String? imagePath, String? prompt, String? language}) async {
    final body = <String, dynamic>{
      'model1': model1,
      'model2': model2,
    };
    if (imagePath != null) body['image_path'] = imagePath;
    if (prompt != null) body['prompt'] = prompt;
    if (language != null) body['language'] = language;

    return await _post('/benchmark/compare', body: body);
  }

  Future<Map<String, dynamic>> getLatestAppVersion() async {
    return await _get('/app/version');
  }

  Future<List<dynamic>> getTelemetryLogs({
    String? program,
    String? module,
    String? action,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (program != null) queryParams['program'] = program;
    if (module != null) queryParams['module'] = module;
    if (action != null) queryParams['action'] = action;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$baseUrl/telemetry/logs').replace(queryParameters: queryParams);
    final response = await _get(uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
    if (response is List) {
      return response;
    }
    throw Exception('Unexpected API response format for /telemetry/logs: $response');
  }

  Future<Map<String, dynamic>> getSystemResources() async {
    final response = await _get('/monitoring/resources');
    if (response is Map<String, dynamic> &&
        response.containsKey('cpu_percent') && response['cpu_percent'] is double &&
        response.containsKey('ram_percent') && response['ram_percent'] is double) {
      return response;
    }
    throw Exception('Unexpected or invalid API response format for /monitoring/resources: $response');
  }

  // Blind Test APIs
  Future<Map<String, dynamic>> getBlindTestPrompt({List<String>? modelExclude}) async {
    final Map<String, dynamic> queryParams = {};
    if (modelExclude != null && modelExclude.isNotEmpty) {
      queryParams['model_exclude'] = modelExclude.join(','); // API expects comma-separated string
    }
    final uri = Uri.parse('$baseUrl/blind_test/prompt').replace(queryParameters: queryParams);
    return await _get(uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
  }

  Future<Map<String, dynamic>> submitBlindTestResult(String modelA, String modelB, String preferredModel, String promptOrImageRef) async {
    final body = <String, dynamic>{
      'model_a': modelA,
      'model_b': modelB,
      'preferred_model': preferredModel,
      'prompt_or_image_ref': promptOrImageRef,
      // 'timestamp' will be set by the backend
    };
    return await _post('/blind_test/submit', body: body);
  }
}
