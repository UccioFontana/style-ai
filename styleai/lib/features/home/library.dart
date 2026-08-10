import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/import_screen.dart';
import 'package:styleai/features/home/home_screen.dart';
import 'package:styleai/features/home/main_menu.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'LIBRARY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'La tua libreria è vuota.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 24),
                ),
              ),
            ),
            MainMenu(
              onHome: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const HomeScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return child;
                    },
                  ),
                );
              },
              onAnalyze: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const ImportScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return child;
                    },
                  ),
                );
              },
              onLibrary: () {},
              activeDestination: MenuDestination.library,
            ),
          ],
        ),
      ),
    );
  }
}
