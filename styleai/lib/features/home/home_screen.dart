import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:dio/dio.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String? _durationText;

  Future<void> pickFile() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'wav',
      ],
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        _selectedFileName = file.name;
        _selectedFile = file;
        _durationText = null;
      });
    } else {
      // L'utente ha annullato
      print("Nessun file selezionato");
    }
  }

  Future<void> startProcess() async {
    if (_selectedFile == null) {
      return;
    }

    if (_selectedFile!.bytes == null) {
      return;
    }

    try {
      final dio = Dio();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
        _selectedFile!.bytes!,
        filename: _selectedFile!.name,
      ),
      });

      final response = await dio.post(
        'http://localhost:8000/songs/analyze',
        data: formData,
        options: Options(
        contentType: 'multipart/form-data',
      ),
      );

      final duration = response.data['duration'];

      setState(() {
        _durationText = duration['formatted'];
      });

      //USARE DURATION PER MOSTRARLO IN UN DIV
    } catch (e) {
    print("Errore durante la chiamata al backend:");
    print(e);
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
                  'Seleziona un file audio per analizzarlo',
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
            if (_selectedFileName != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: startProcess,
                child: const Text("Avvia"),
              ),
            ],
            if (_durationText != null) ...[
              const SizedBox(height: 16),
              Text("Il file ha durata: ${_durationText!}"),
            ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}