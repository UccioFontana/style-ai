import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/utils/frequency_mapper.dart';
import 'package:styleai/features/analyze/utils/metrics_mapper.dart';
import 'package:styleai/features/analyze/widgets/ai_review_box.dart';
import 'package:styleai/features/analyze/widgets/metrics_table.dart';
import 'package:styleai/features/analyze/widgets/nerd_details.dart';
import 'package:styleai/features/analyze/widgets/overview_cards.dart';
import 'package:styleai/features/analyze/widgets/tonal_balance_chart.dart';
import 'package:styleai/features/analyze/widgets/tonal_balance_table.dart';

class AnalysisResultScreen extends StatelessWidget {
  final dynamic responseData;

  const AnalysisResultScreen({
    super.key,
    required this.responseData,
    
  });

  @override
  Widget build(BuildContext context) {
    final aiReviewText = MetricsMapper.extractAiReview(responseData);
    final technicalRows = MetricsMapper.buildRows(responseData);
    final tonalRows = FrequencyMapper.buildTonalRows(responseData);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.textPrimary,
          title: const Text('Risultato analisi'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.textPrimary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'AI Review'),
              Tab(text: 'Technical'),
              Tab(text: 'Tonal Balance'),
              Tab(text: 'Nerd'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResultTab(
              child: OverviewCards(responseData: responseData),
            ),
            _ResultTab(
              child: aiReviewText.isEmpty
                  ? _EmptyState(message: 'Nessuna review AI disponibile.')
                  : AiReviewBox(text: aiReviewText),
            ),
            _ResultTab(
              child: technicalRows.isEmpty
                  ? _EmptyState(message: 'Nessuna metrica tecnica disponibile.')
                  : MetricsTable(rows: technicalRows),
            ),
            _ResultTab(
              child: Column(
                children: [
                  TonalBalanceChart(rows: tonalRows),
                  const SizedBox(height: 24),
                  TonalBalanceTable(rows: tonalRows),
                ],
              ),
            ),
            _ResultTab(
              child: NerdDetails(responseData: responseData),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTab extends StatelessWidget {
  final Widget child;

  const _ResultTab({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: child,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 16,
      ),
    );
  }
}