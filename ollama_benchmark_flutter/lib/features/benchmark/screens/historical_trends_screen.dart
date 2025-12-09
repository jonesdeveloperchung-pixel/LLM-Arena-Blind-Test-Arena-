import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/telemetry.dart';

class HistoricalTrendsScreen extends ConsumerStatefulWidget {
  final String category;
  const HistoricalTrendsScreen({super.key, required this.category});

  @override
  ConsumerState<HistoricalTrendsScreen> createState() => _HistoricalTrendsScreenState();
}

class _HistoricalTrendsScreenState extends ConsumerState<HistoricalTrendsScreen> {
  List<dynamic> _historicalData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    final apiClient = ref.read(apiClientProvider);
    final telemetry = ref.read(telemetryServiceProvider);
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await apiClient.getBenchmarkHistory(widget.category);
      if (mounted) {
        setState(() {
          _historicalData = data;
        });
        telemetry.trackEvent('historical_trends', 'fetch_data_success', details: {'category': widget.category});
      }
    } catch (e) {
      telemetry.trackEvent('historical_trends', 'fetch_data_failure', error: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load historical data: $e')),
        );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.category} 歷史趨勢 (Historical Trends)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_historicalData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.category} 歷史趨勢 (Historical Trends)')),
        body: const Center(child: Text('沒有找到歷史數據 (No historical data found)')),
      );
    }

    // Prepare data for the LineChart
    List<FlSpot> scoreSpots = [];
    double minScore = 5.0;
    double maxScore = 0.0;
    double minX = 0;
    double maxX = _historicalData.length.toDouble() - 1;

    for (int i = 0; i < _historicalData.length; i++) {
      final entry = _historicalData[i];
      final score = entry['score']?.toDouble() ?? 0.0;
      scoreSpots.add(FlSpot(i.toDouble(), score));
      if (score < minScore) minScore = score;
      if (score > maxScore) maxScore = score;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} 歷史趨勢 (Historical Trends)'),
        backgroundColor: const Color(0xFF1E293B), // Slate 800
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F172A), // Slate 950
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: const Color(0xFF1E293B), // Slate 800
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.category} 分數隨時間變化 (Score over Time)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _historicalData.length) return const Text('');
                              final timestamp = _historicalData[value.toInt()]['run_timestamp'];
                              final dateTime = DateTime.parse(timestamp);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(DateFormat('MM/dd HH:mm').format(dateTime), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xff37434d), width: 1),
                      ),
                      minX: minX,
                      maxX: maxX,
                      minY: minScore > 0 ? minScore - 0.5 : 0, // Give some padding below min score
                      maxY: maxScore < 5 ? maxScore + 0.5 : 5.0, // Give some padding above max score
                      lineBarsData: [
                        LineChartBarData(
                          spots: scoreSpots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent,
                              Colors.blueAccent,
                            ],
                          ),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyanAccent.withOpacity(0.3),
                                Colors.blueAccent.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}