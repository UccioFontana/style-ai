import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:styleai/core/theme/app_theme.dart';

// 1 - Mostra sul testo del bottone il file selezionato

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFileName;

  Future<void> pickFile() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'wav',
      ],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        _selectedFileName = file.name;
      });
    } else {
      // L'utente ha annullato
      print("Nessun file selezionato");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Row(
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
            ],
          ),
        Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
                  'Importa un file!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ElevatedButton(
              onPressed: pickFile,
              child: Text(
                _selectedFileName ?? "Importa file",
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}