// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get benchmarkAppTitle => '模型能力評測';

  @override
  String get benchmarkCategoryReasoning => '推理';

  @override
  String get benchmarkCategoryCoding => '編碼';

  @override
  String get benchmarkCategoryVision => '視覺';

  @override
  String get benchmarkCategoryLanguage => '語言';

  @override
  String get benchmarkCategoryEmbedding => '嵌入';

  @override
  String get benchmarkSamplePrompt => '用於檢查推理能力的範例提示...';

  @override
  String get benchmarkJudgesAnalysis => '評審分析';

  @override
  String get benchmarkRunningStatus => '執行基準測試中...';

  @override
  String get benchmarkNoResults => '此類別尚無基準測試結果。請運行測試！';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get benchmarkAppTitle => '模型能力評測';

  @override
  String get benchmarkCategoryReasoning => '推理';

  @override
  String get benchmarkCategoryCoding => '編碼';

  @override
  String get benchmarkCategoryVision => '視覺';

  @override
  String get benchmarkCategoryLanguage => '語言';

  @override
  String get benchmarkCategoryEmbedding => '嵌入';

  @override
  String get benchmarkSamplePrompt => '用於檢查推理能力的範例提示...';

  @override
  String get benchmarkJudgesAnalysis => '評審分析';

  @override
  String get benchmarkRunningStatus => '執行基準測試中...';

  @override
  String get benchmarkNoResults => '此類別尚無基準測試結果。請運行測試！';
}
