import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm_arena_blind_test_arena/core/api_client.dart';
import 'package:llm_arena_blind_test_arena/core/telemetry.dart';

// Provider for ApiClient
final apiClientProvider = Provider((ref) => ApiClient());

// Provider for TelemetryService
final telemetryServiceProvider = Provider((ref) => TelemetryService());
