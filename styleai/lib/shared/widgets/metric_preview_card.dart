import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class MetricPreviewCard extends StatelessWidget {
  const MetricPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 430,
        ),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceLight,
              AppTheme.surface,
              AppTheme.primary.withOpacity(0.10),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildScore(),
            const SizedBox(height: 28),
            _buildMetricRow(
              label: 'Integrated LUFS',
              value: '-8.5',
              status: 'Competitive',
              color: AppTheme.success,
            ),
            _buildMetricRow(
              label: 'True Peak',
              value: '-0.2 dBTP',
              status: 'Risky',
              color: AppTheme.warning,
            ),
            _buildMetricRow(
              label: 'Low-mid buildup',
              value: '+3.1 dB',
              status: 'Check',
              color: AppTheme.danger,
            ),
            _buildMetricRow(
              label: 'Stereo correlation',
              value: '0.72',
              status: 'Stable',
              color: AppTheme.success,
            ),
            const SizedBox(height: 22),
            _buildWarningBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mix Technical Report',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Demo analysis preview',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          '78',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 58,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '/ 100',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Medium Risk',
            style: TextStyle(
              color: AppTheme.warning,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.danger.withOpacity(0.25),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.danger,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Accumulo evidente nella zona 180–300 Hz. Potrebbe ridurre la chiarezza del mix su speaker piccoli.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}