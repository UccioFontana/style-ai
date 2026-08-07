import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/analyze_result_screen.dart';
import 'package:styleai/features/analyze/services/audio_analysis_api.dart';
import 'package:styleai/features/home/home_screen.dart';
import 'package:styleai/features/home/library.dart';
import 'package:styleai/features/home/main_menu.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final AudioAnalysisApi _api = AudioAnalysisApi();

  String? _selectedFileName;
  PlatformFile? _selectedFile;

  bool _isLoading = false;
  String? _errorMessage;

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
    });

    try {
      final responseData = await _api.analyzeFile(_selectedFile!);

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
      setState(() {
        _isLoading = false;
        _errorMessage = "Errore durante l'analisi del file.";
      });
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  void _goToLibrary() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LibraryScreen(),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                    ],
                  ),
                ),
              ),
            ),
            MainMenu(
              onHome: _goToHome,
              onAnalyze: () {},
              onLibrary: _goToLibrary,
              activeDestination: MenuDestination.analyze,
            ),
          ],
        ),
      ),
    );
  }
}