import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_record.dart';
import '../services/database_service.dart';

class WeeklyChartScreen extends StatefulWidget {
  const WeeklyChartScreen({super.key});

  @override
  State<WeeklyChartScreen> createState() => _WeeklyChartScreenState();
}

class _WeeklyChartScreenState extends State<WeeklyChartScreen> {
  final DatabaseService _db = DatabaseService();
  List<DailyRecord> _records = [];
  double _dailyLimit = 160.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _db.getWeeklyRecords();
    setState(() {
      _records = records;
      if (records.isNotEmpty) {
        _dailyLimit = records.last.dailyLimit;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Weekly Overview',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No data yet',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start logging expenses to see your chart',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last 7 Days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daily spending vs your limit of ₹${_dailyLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY(),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipRoundedRadius: 8,
                                getTooltipItem: (group, groupIndex, rod,
                                    rodIndex) {
                                  final record = _records[group.x.toInt()];
                                  return BarTooltipItem(
                                    '₹${record.totalSpent.toStringAsFixed(0)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= _records.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = DateFormat('yyyy-MM-dd')
                                        .parse(_records[idx].date);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('E').format(date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _dailyLimit / 2,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: _dailyLimit,
                                  color: Colors.red.shade300,
                                  strokeWidth: 2,
                                  dashArray: [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    labelResolver: (_) => 'Limit',
                                  ),
                                ),
                              ],
                            ),
                            barGroups: _records
                                .asMap()
                                .entries
                                .map((entry) {
                              final idx = entry.key;
                              final record = entry.value;
                              final exceeded =
                                  record.totalSpent > record.effectiveLimit;
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: record.totalSpent,
                                    color: exceeded
                                        ? Colors.red.shade400
                                        : const Color(0xFF2E7D32),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Summary stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _statItem(
                              'Total',
                              '₹${_totalSpent().toStringAsFixed(0)}',
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.grey.shade300,
                            ),
                            _statItem(
                              'Average',
                              '₹${_averageSpent().toStringAsFixed(0)}',
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.grey.shade300,
                            ),
                            _statItem(
                              'Days Over',
                              '${_daysOverLimit()}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = _dailyLimit;
    for (final r in _records) {
      if (r.totalSpent > max) max = r.totalSpent;
    }
    return max * 1.2;
  }

  double _totalSpent() {
    double total = 0;
    for (final r in _records) {
      total += r.totalSpent;
    }
    return total;
  }

  double _averageSpent() {
    if (_records.isEmpty) return 0;
    return _totalSpent() / _records.length;
  }

  int _daysOverLimit() {
    int count = 0;
    for (final r in _records) {
      if (r.totalSpent > r.effectiveLimit) count++;
    }
    return count;
  }
}
