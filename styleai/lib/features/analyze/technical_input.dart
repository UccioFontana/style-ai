import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/analyze_result_screen.dart';
import 'package:styleai/features/analyze/artistic_input.dart';
import 'package:styleai/features/analyze/import_screen.dart';
import 'package:styleai/features/analyze/services/audio_analysis_api.dart';
import 'package:styleai/features/home/home_screen.dart';
import 'package:styleai/features/home/library.dart';
import 'package:styleai/features/home/main_menu.dart';

enum Daws {
  None,
  LogicPro,
  AbletonLive,
  FLStudio,
  Cubase,
  ProTools,
  StudioOne,
  Reaper,
  GarageBand,
  Reason,
  BitwigStudio,
  Cakewalk,
  DigitalPerformer,
  Sonar,
  Tracktion,
  Ardour,
  Mixcraft,
  Samplitude,
  Nuendo,
  Other,
}

Daws selectedDaw = Daws.None;

final List<String> instruments = [];

class TechnicalInput extends StatefulWidget {
  const TechnicalInput({
    super.key,
    required this.selectedFile,
  });

  final PlatformFile selectedFile;

  @override
  State<TechnicalInput> createState() => _TechnicalInputState();
}

class _TechnicalInputState extends State<TechnicalInput> {

  final TextEditingController instrumentController = TextEditingController();

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
                    'DATI TECNICI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Seleziona la tua DAW',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                DropdownButton<Daws>(
                  value: selectedDaw,
                  items: Daws.values.map((Daws daw) {
                    return DropdownMenuItem<Daws>(
                      value: daw,
                      child: Text(daw.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (Daws? newValue) {
                    setState(() {
                      selectedDaw = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: instrumentController,
                          decoration: InputDecoration(
                            labelText: 'Inserisci strumento...',
                            labelStyle: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: AppTheme.textPrimary,
                        onPressed: () {
                          setState(() {
                            instruments.add(instrumentController.text);
                            instrumentController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (instruments.isEmpty)
                        const Text(
                          'Nessuno strumento aggiunto',
                        style: TextStyle(color: Colors.white),
                      )
                      else ...[
                        const Text(
                          'Strumenti aggiunti:',
                          style: TextStyle(color: Colors.white),
                        ),
                        for (var instrument in instruments)
                          Row(
                            children: [
                              Text(
                                instrument,
                                style: const TextStyle(color: Colors.white),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                color: AppTheme.textPrimary,
                                onPressed: () {
                                  setState(() {
                                    instruments.remove(instrument);
                                  });
                                },
                              ),
                            ],
                          ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding : const EdgeInsets.symmetric(horizontal: 60),
                  child:  
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ 
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => ImportScreen(
                                  ),
                                  transitionsBuilder: (_, animation, __, child) {
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
                            onPressed: () { 
                              print('Selected file name: ${widget.selectedFile.name}');
                              if(instruments.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aggiungi almeno uno strumento prima di procedere.'),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                  ),
                                );
                                return;
                              }
                              else{
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => ArtisticInput(
                                      selectedFile: widget.selectedFile,
                                      daw: selectedDaw.toString(),
                                      instruments: instruments,
                                    ),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return child;
                                    },
                                  ),
                                );
                              }
                            },
                            child: const Text('Procedi'),
                          ),
                        ),
                      ],
                    ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}