import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFileName;
  PlatformFile? _selectedFile;

  bool _isLoading = false;
  String? _errorMessage;
  String? _aiReviewText;

  List<MapEntry<String, String>> _metricsRows = [];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
      withData: true,
    );

    if (result == null) {
      return;
    }

    final file = result.files.first;

    setState(() {
      _selectedFileName = file.name;
      _selectedFile = file;
      _metricsRows = [];
      _aiReviewText = null;
      _errorMessage = null;
    });
  }

  Future<void> startProcess() async {
    if (_selectedFile?.bytes == null) {
      setState(() {
        _errorMessage = 'Nessun file valido selezionato.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiReviewText = null;
      _metricsRows = [];
    });

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      });

      final response = await Dio().post(
        'http://localhost:8000/songs/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      setState(() {
        _metricsRows = _buildRows(response.data);
        _aiReviewText = response.data['ai_mix_review']?['text'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Errore durante l'analisi del file.";
      });
    }
  }

  List<MapEntry<String, String>> _buildRows(dynamic responseData) {
    final metrics = responseData['technical_metrics'];

    dynamic v(List<String> path) {
      dynamic current = metrics;

      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }

      return current;
    }

    return [
      MapEntry(
        'LUFS integrated',
        _format(v(['loudness', 'lufs_integrated']), suffix: ' LUFS'),
      ),
      MapEntry(
        'LUFS short-term',
        _formatLufsList(v(['loudness', 'lufs_short_term'])),
      ),
      MapEntry(
        'LUFS momentary',
        _formatLufsList(v(['loudness', 'lufs_momentary'])),
      ),
      MapEntry(
        'True Peak',
        _format(v(['peaks', 'true_peak_dbtp']), suffix: ' dBTP'),
      ),
      MapEntry(
        'Peak massimo',
        _format(v(['peaks', 'max_peak_dbfs']), suffix: ' dBFS'),
      ),
      MapEntry(
        'Peak massimo lineare',
        _format(v(['peaks', 'max_peak_linear'])),
      ),
      MapEntry(
        'RMS',
        _format(v(['dynamics', 'rms_dbfs']), suffix: ' dBFS'),
      ),
      MapEntry(
        'RMS lineare',
        _format(v(['dynamics', 'rms_linear'])),
      ),
      MapEntry(
        'Crest Factor',
        _format(v(['dynamics', 'crest_factor_db']), suffix: ' dB'),
      ),
      MapEntry(
        'Crest Factor lineare',
        _format(v(['dynamics', 'crest_factor_linear'])),
      ),
      MapEntry(
        'Durata',
        _format(v(['audio_properties', 'duration', 'formatted'])),
      ),
      MapEntry(
        'Sample rate',
        _format(v(['audio_properties', 'sample_rate']), suffix: ' Hz'),
      ),
      MapEntry(
        'Canali',
        _format(v(['audio_properties', 'channels'])),
      ),
      MapEntry(
        'Bit depth',
        _format(v(['audio_properties', 'bit_depth']), suffix: ' bit'),
      ),
      MapEntry(
        'Formato',
        _format(v(['audio_properties', 'format'])),
      ),
      MapEntry(
        'Subtype',
        _format(v(['audio_properties', 'subtype'])),
      ),
      MapEntry(
        'Clipping detection',
        v(['clipping', 'clipping_detected']) == true ? 'Sì' : 'No',
      ),
      MapEntry(
        'Campioni clipped',
        _format(v(['clipping', 'clipped_samples'])),
      ),
      MapEntry(
        'Clipping %',
        _format(v(['clipping', 'clipping_percentage']), suffix: ' %'),
      ),
      MapEntry(
        'Headroom residua',
        _format(v(['headroom', 'headroom_db']), suffix: ' dB'),
      ),
    ];
  }

  String _format(dynamic value, {String suffix = ''}) {
    if (value == null) {
      return 'Non disponibile';
    }

    return '$value$suffix';
  }

  String _formatLufsList(dynamic values) {
    if (values == null || values is! List || values.isEmpty) {
      return 'Non disponibile';
    }

    final lufsValues = values
        .map((item) => item is Map ? item['lufs'] : null)
        .where((value) => value != null)
        .map((value) => double.tryParse(value.toString()))
        .whereType<double>()
        .toList();

    if (lufsValues.isEmpty) {
      return 'Non disponibile';
    }

    final min = lufsValues.reduce((a, b) => a < b ? a : b);
    final max = lufsValues.reduce((a, b) => a > b ? a : b);
    final avg = lufsValues.reduce((a, b) => a + b) / lufsValues.length;

    return 'Avg: ${avg.toStringAsFixed(2)} LUFS | '
        'Min: ${min.toStringAsFixed(2)} | '
        'Max: ${max.toStringAsFixed(2)} | '
        '${lufsValues.length} finestre';
  }

  Widget _buildAiReviewBox() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
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
            'Conclusioni AI sul mix',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _aiReviewText ?? '',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTable() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
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
          ..._metricsRows.map(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'STYLE-AI',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 80),
                    Text(
                      'Seleziona un file audio per analizzarlo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : pickFile,
                      child: Text(_selectedFileName ?? 'Importa file'),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : startProcess,
                        child: Text(
                          _isLoading ? 'Analisi in corso...' : 'Avvia',
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    if (_aiReviewText != null && _aiReviewText!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildAiReviewBox(),
                    ],
                    if (_metricsRows.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildMetricsTable(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}