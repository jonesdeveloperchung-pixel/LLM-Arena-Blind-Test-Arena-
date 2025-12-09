// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get benchmarkAppTitle => 'Model Capability Benchmarking';

  @override
  String get benchmarkCategoryReasoning => 'Reasoning';

  @override
  String get benchmarkCategoryCoding => 'Coding';

  @override
  String get benchmarkCategoryVision => 'Vision';

  @override
  String get benchmarkCategoryLanguage => 'Language';

  @override
  String get benchmarkCategoryEmbedding => 'Embedding';

  @override
  String get benchmarkSamplePrompt =>
      'Sample prompt for reasoning capability check...';

  @override
  String get benchmarkJudgesAnalysis => 'Judge\'s Analysis';

  @override
  String get benchmarkRunningStatus => 'Running benchmark...';

  @override
  String get benchmarkNoResults =>
      'No benchmark results yet for this category. Run a test!';
}
