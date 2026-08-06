import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class StyleAIApp extends StatelessWidget {
  const StyleAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STYLE-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}