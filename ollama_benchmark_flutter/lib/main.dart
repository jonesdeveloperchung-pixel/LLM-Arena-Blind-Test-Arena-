import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:llm_arena_blind_test_arena/l10n/app_localizations.dart'; // Import AppLocalizations
import 'features/benchmark/screens/benchmark_home_screen.dart';
import 'features/pipeline/screens/pipeline_dashboard_screen.dart';
import 'features/benchmark/screens/rollback_management_screen.dart';
import 'features/pipeline/screens/alert_dashboard_screen.dart';
import 'core/telemetry.dart';
import 'core/providers.dart'; // Add this import

void main() {
  TelemetryService().log(module: 'system', action: 'startup', command: 'app_launch');
  runApp(const ProviderScope(child: OllamaBenchmarkApp()));
}

class OllamaBenchmarkApp extends StatelessWidget {
  const OllamaBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLM Arena 盲測競技場',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF10B981), // Vibrant Emerald Green
          onPrimary: Colors.white,
          secondary: const Color(0xFF38BDF8), // Softer Blue-Green
          onSecondary: Colors.black,
          error: const Color(0xFFEF4444), // Red-500
          onError: Colors.white,
          background: const Color(0xFF0F172A), // Deep Slate-900
          onBackground: Colors.white70,
          surface: const Color(0xFF1E293B), // Slate-800
          onSurface: Colors.white70,
          surfaceVariant: const Color(0xFF334155), // Slate-700
          onSurfaceVariant: Colors.white70,
        ),
        fontFamily: 'Noto Sans TC', // Primary font
        fontFamilyFallback: ['Roboto', 'sans-serif'], // Fallback fonts for other languages and symbols
      ),
      // Localization for Safe Defaults (Traditional Chinese)
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add AppLocalizations delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'), // Traditional Chinese
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'TW'), // Set Traditional Chinese as default
      home: const MainScreen(),
    );
  }
}


class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BenchmarkHomeScreen(),
    const PipelineDashboardScreen(),
    const RollbackManagementScreen(), // Add RollbackManagementScreen
    const AlertDashboardScreen(), // Add AlertDashboardScreen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              String tabName;
              if (index == 0) {
                tabName = 'benchmark';
              } else if (index == 1) {
                tabName = 'pipeline';
              } else if (index == 2) {
                tabName = 'rollback';
              } else {
                tabName = 'alerts'; // New tab
              }
              ref.read(telemetryServiceProvider).trackEvent('navigation', 'switch_tab', details: {'tab_name': tabName});
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.onSurfaceVariant),
                selectedIcon: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.onPrimary),
                label: Text('基準測試\n(Benchmark)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.view_list, color: Theme.of(context).colorScheme.onSurfaceVariant),
                selectedIcon: Icon(Icons.view_list, color: Theme.of(context).colorScheme.onPrimary),
                label: Text('處理管道\n(Pipeline)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              NavigationRailDestination( // New Rollback tab
                icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onSurfaceVariant),
                selectedIcon: Icon(Icons.history, color: Theme.of(context).colorScheme.onPrimary),
                label: Text('回復設定\n(Rollback)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              NavigationRailDestination( // New Alerts tab
                icon: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.onSurfaceVariant),
                selectedIcon: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.onPrimary),
                label: Text('告警儀表板\n(Alerts)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
