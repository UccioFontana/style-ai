import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/utils/frequency_mapper.dart';

class TonalBalanceTable extends StatelessWidget {
  final List<TonalBandRow> rows;

  const TonalBalanceTable({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Table(
        border: TableBorder.all(
          color: AppTheme.textSecondary.withOpacity(0.4),
        ),
        columnWidths: const {
          0: FlexColumnWidth(1.1),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
            ),
            children: [
              _cell('Banda', isHeader: true),
              _cell('Range', isHeader: true),
              _cell('Energia', isHeader: true),
              _cell('Status', isHeader: true),
              _cell('Avg dB', isHeader: true),
            ],
          ),
          ...rows.map(
            (row) => TableRow(
              children: [
                _cell(row.label),
                _cell(row.range),
                _cell(row.energyText),
                _cell(row.status),
                _cell(row.avgDb),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: isHeader ? 15 : 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}