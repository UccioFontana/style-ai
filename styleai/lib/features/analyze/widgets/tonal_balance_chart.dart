import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/utils/frequency_mapper.dart';

class TonalBalanceChart extends StatelessWidget {
  final List<TonalBandRow> rows;

  const TonalBalanceChart({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'Nessun dato frequenziale disponibile.',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 850),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Energia per banda frequenziale',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: BarChart(
              BarChartData(
                maxY: _getMaxY(),
                barGroups: _buildGroups(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textSecondary.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= rows.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            rows[index].label,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildGroups() {
    return rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: row.energyPercent,
            width: 24,
            color: _barColor(row.status),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    final maxValue = rows
        .map((row) => row.energyPercent)
        .fold<double>(0, (a, b) => a > b ? a : b);

    if (maxValue <= 10) {
      return 10;
    }

    return maxValue + 8;
  }

  Color _barColor(String status) {
    switch (status) {
      case 'Alto':
        return Colors.orange;
      case 'Basso':
        return Colors.blueAccent;
      case 'Normale':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }
}