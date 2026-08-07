import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';

class MetricsTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;

  const MetricsTable({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 750),
      child: Table(
        border: TableBorder.all(
          color: AppTheme.textSecondary.withOpacity(0.4),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.8),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
            ),
            children: [
              _cell('Metrica', isHeader: true),
              _cell('Valore', isHeader: true),
            ],
          ),
          ...rows.map(
            (row) => TableRow(
              children: [
                _cell(row.key),
                _cell(row.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: isHeader ? 16 : 14,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}