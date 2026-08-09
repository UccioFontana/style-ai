import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/utils/frequency_mapper.dart';

class StereoPhaseDetails extends StatelessWidget {
  final dynamic responseData;

  const StereoPhaseDetails({
    super.key,
    required this.responseData,
  });

  @override
  Widget build(BuildContext context) {
    final tonalRows = FrequencyMapper.buildTonalRows(responseData);
    final frameStatsRows = FrequencyMapper.buildFrameStatsRows(responseData);
    final qualityRows = FrequencyMapper.buildQualityRows(responseData);

    return Container(
      constraints: const BoxConstraints(maxWidth: 950),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informazioni stereo & fase',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Meter globale',
            child: Text(
              'Inserire qui i dettagli sul meter globale estratti dall\'analisi audio.',
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Dettagli di fase',
            child: Text(
              'Inserire qui i dettagli di fase e le informazioni stereo estratte dall\'analisi audio.',
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Bilanciamento L/R e Mid/Side',
            child: Text(
              'Inserire qui le informazioni sul bilanciamento L/R e Mid/Side estratte dall\'analisi audio.',
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Rischio stereo nel low-end',
            child: Text(
              'Inserire qui le informazioni sul rischio stereo nel low-end estratte dall\'analisi audio.',
            ),
          ),
          const SizedBox(height: 24),
          _section(
            title: 'Compatibilità mono',
            child: Text(
              'Inserire qui le informazioni sulla compatibilità mono estratte dall\'analisi audio.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _keyValueTable(List<MapEntry<String, String>> rows) {
    return Table(
      border: TableBorder.all(
        color: AppTheme.textSecondary.withOpacity(0.25),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(2),
      },
      children: rows.map(
        (row) {
          return TableRow(
            children: [
              _cell(row.key, isHeader: true),
              _cell(row.value),
            ],
          );
        },
      ).toList(),
    );
  }

  Widget _percentileTable(List<TonalBandRow> rows) {
    return Table(
      border: TableBorder.all(
        color: AppTheme.textSecondary.withOpacity(0.25),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
          ),
          children: [
            _cell('Banda', isHeader: true),
            _cell('p10', isHeader: true),
            _cell('p50', isHeader: true),
            _cell('p90', isHeader: true),
            _cell('Peak', isHeader: true),
            _cell('Var.', isHeader: true),
          ],
        ),
        ...rows.map(
          (row) => TableRow(
            children: [
              _cell(row.label),
              _cell(row.p10Db),
              _cell(row.p50Db),
              _cell(row.p90Db),
              _cell(row.peakDb),
              _cell(row.variationDb),
            ],
          ),
        ),
      ],
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
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          height: 1.35,
        ),
      ),
    );
  }

  String _prettyJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}