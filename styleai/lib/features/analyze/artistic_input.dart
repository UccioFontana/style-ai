import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/analyze_result_screen.dart';
import 'package:styleai/features/analyze/services/audio_analysis_api.dart';
import 'package:styleai/features/analyze/technical_input.dart';

class ArtisticInput extends StatefulWidget {
  const ArtisticInput({
    super.key,
    required this.selectedFile,
    required this.daw,
    required this.instruments,
  });

  final PlatformFile selectedFile;
  final String daw;
  final List<String> instruments;

  @override
  State<ArtisticInput> createState() => _ArtisticInputState();
}

class _ArtisticInputState extends State<ArtisticInput> {
  double warmth = 0.5;
  double brightness = 0.5;
  double intimacy = 0.5;
  double aggression = 0.5;
  double processing = 0.5;
  double instrumental = 0.5;

  Map<String, double> feeling = {};

  bool _isLoading = false;
  String? _errorMessage;

  final AudioAnalysisApi _api = AudioAnalysisApi();

  Future<void> startProcess() async {
    debugPrint('Starting analysis process...');
    debugPrint('Selected file name: ${widget.selectedFile.name}');
    debugPrint('Selected file size: ${widget.selectedFile.size}');
    debugPrint('DAW: ${widget.daw}');
    debugPrint('Instruments: ${widget.instruments}');
    debugPrint('Feeling: $feeling');

    if (widget.selectedFile.bytes == null) {
      setState(() {
        _errorMessage = 'Nessun file valido selezionato.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responseData = await _api.analyzeFile(
        widget.selectedFile,
        widget.daw,
        feeling,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(
            responseData: responseData,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Errore analisi: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Errore durante l\'analisi del file.';
      });
    }
  }

  void createFeelingMap() {
    feeling = {
      'warmth': warmth,
      'brightness': brightness,
      'intimacy': intimacy,
      'aggression': aggression,
      'processing': processing,
      'instrumental': instrumental,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'DATI ARTISTICI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                buildFeelingSlider(
                  leftLabel: 'Freddo',
                  rightLabel: 'Caldo',
                  value: warmth,
                  onChanged: (value) {
                    setState(() {
                      warmth = value;
                    });
                  },
                ),

                buildFeelingSlider(
                  leftLabel: 'Scuro',
                  rightLabel: 'Luminoso',
                  value: brightness,
                  onChanged: (value) {
                    setState(() {
                      brightness = value;
                    });
                  },
                ),

                buildFeelingSlider(
                  leftLabel: 'Aperto',
                  rightLabel: 'Intimo',
                  value: intimacy,
                  onChanged: (value) {
                    setState(() {
                      intimacy = value;
                    });
                  },
                ),

                buildFeelingSlider(
                  leftLabel: 'Calmo',
                  rightLabel: 'Aggressivo',
                  value: aggression,
                  onChanged: (value) {
                    setState(() {
                      aggression = value;
                    });
                  },
                ),

                buildFeelingSlider(
                  leftLabel: 'Naturale',
                  rightLabel: 'Processato',
                  value: processing,
                  onChanged: (value) {
                    setState(() {
                      processing = value;
                    });
                  },
                ),

                buildFeelingSlider(
                  leftLabel: 'Orientato alla voce',
                  rightLabel: 'Orientato agli strumenti',
                  value: instrumental,
                  onChanged: (value) {
                    setState(() {
                      instrumental = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          TechnicalInput(
                                        selectedFile: widget.selectedFile,
                                      ),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                        return child;
                                      },
                                    ),
                                  );
                                },
                          child: const Text('Indietro'),
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  createFeelingMap();
                                  startProcess();
                                },
                          child: Text(
                            _isLoading
                                ? 'Analisi in corso...'
                                : 'Avvia Analisi',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFeelingSlider({
    required String leftLabel,
    required String rightLabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 10,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftLabel,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                rightLabel,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.textSecondary,
              inactiveTrackColor:
                  AppTheme.textSecondary.withOpacity(0.3),
              thumbColor: AppTheme.textPrimary,
              overlayColor:
                  AppTheme.textPrimary.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}