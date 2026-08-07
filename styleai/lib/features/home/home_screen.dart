import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';
import 'package:styleai/features/analyze/analyze_screen.dart';
import 'package:styleai/features/home/library.dart';
import 'package:styleai/features/home/main_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Titolo
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'STYLE AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Parte centrale
            Expanded(
              child: Center(
                child: Text(
                  'Benvenuto in STYLE AI!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            MainMenu(
              onHome: () {},
              onAnalyze: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AnalyzeScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return child;
                    },
                  ),
                );
              },
              onLibrary: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LibraryScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return child;
                    },
                  ),
                );
              },
              activeDestination: MenuDestination.home,
            ),
          ],
        ),
      ),
    );
  }
}
