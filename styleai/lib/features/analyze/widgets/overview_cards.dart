import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/utils/frequency_mapper.dart';
import 'package:styleai/features/analyze/utils/metrics_mapper.dart';

class OverviewCards extends StatelessWidget {
  final dynamic responseData;

  const OverviewCards({
    super.key,
    required this.responseData,
  });

  @override
  Widget build(BuildContext context) {
    final warnings = FrequencyMapper.extractWarnings(responseData);

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _card(
                title: 'LUFS',
                value: MetricsMapper.format(
                  MetricsMapper.getTechnicalValue(
                    responseData,
                    ['loudness', 'lufs_integrated'],
                  ),
                  suffix: ' LUFS',
                ),
              ),
              _card(
                title: 'True Peak',
                value: MetricsMapper.format(
                  MetricsMapper.getTechnicalValue(
                    responseData,
                    ['peaks', 'true_peak_dbtp'],
                  ),
                  suffix: ' dBTP',
                ),
              ),
              _card(
                title: 'Headroom',
                value: MetricsMapper.format(
                  MetricsMapper.getTechnicalValue(
                    responseData,
                    ['headroom', 'headroom_db'],
                  ),
                  suffix: ' dB',
                ),
              ),
              _card(
                title: 'Clipping',
                value: MetricsMapper.getTechnicalValue(
                          responseData,
                          ['clipping', 'clipping_detected'],
                        ) ==
                        true
                    ? 'Sì'
                    : 'No',
              ),
              _card(
                title: 'Tonal Profile',
                value: FrequencyMapper.extractTonalProfile(responseData),
              ),
              _card(
                title: 'Banda dominante',
                value: FrequencyMapper.extractDominantBand(responseData),
              ),
              _card(
                title: 'Low-end',
                value: FrequencyMapper.extractLowEndPercent(responseData),
              ),
              _card(
                title: 'High-end',
                value: FrequencyMapper.extractHighEndPercent(responseData),
              ),
              _card(
                title: 'Confidence',
                value: FrequencyMapper.extractConfidence(responseData),
              ),
            ],
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 32),
            _warningsBox(warnings),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String value,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningsBox(List<String> warnings) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warning principali',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...warnings.take(3).map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $warning',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}