import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:styleai/core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;

      print(file.name);
      print(file.path);
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
                "Importa file",
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