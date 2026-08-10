import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/analyze_result_screen.dart';
import 'package:styleai/features/analyze/services/audio_analysis_api.dart';
import 'package:styleai/features/home/home_screen.dart';
import 'package:styleai/features/home/library.dart';
import 'package:styleai/features/home/main_menu.dart';
import 'package:styleai/features/analyze/technical_input.dart';



class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final AudioAnalysisApi _api = AudioAnalysisApi();

  String? _selectedFileName;
  PlatformFile? _selectedFile;

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
      withData: kIsWeb,
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

                  //MAIN COLUMN

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'STYLE AI',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 80),

                      //DESCRIPTION TEXT
                      
                      Text(
                        'Seleziona un file audio e la DAW per l\'analisi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 24),

                      //IMPORT BUTTON

                      ElevatedButton(
                        onPressed: _isLoading ? null : pickFile,
                        child: Text(_selectedFileName ?? 'Importa file'),
                      ),
                      const SizedBox(height: 16),

                      // PROCEED BUTTON

                      if (_selectedFileName != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          //onPressed: _isLoading ? null : startProcess,
                          onPressed: () {
                            if (_selectedFile == null) return;

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TechnicalInput(
                                  selectedFile: _selectedFile!,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            _isLoading ? 'Caricamento...' : 'Prosegui',
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