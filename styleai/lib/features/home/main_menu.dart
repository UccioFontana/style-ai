import 'package:flutter/material.dart';
import 'package:styleai/core/theme/app_theme.dart';

enum MenuDestination { home, analyze, library }

class MainMenu extends StatelessWidget {
  const MainMenu({
    required this.onHome,
    required this.onAnalyze,
    required this.onLibrary,
    required this.activeDestination,
    super.key,
  });

  final VoidCallback onHome;
  final VoidCallback onAnalyze;
  final VoidCallback onLibrary;
  final MenuDestination activeDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 5, 5, 3),
      decoration: const BoxDecoration(
        color: AppTheme.textSecondary,
        /*gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF1A2233), AppTheme.surface, AppTheme.background],
        ),*/
        //borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppTheme.textSecondary)),
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MenuItem(
              label: 'Home',
              assetPath: 'assets/images/home_image.png',
              isActive: activeDestination == MenuDestination.home,
              onPressed: onHome,
            ),
          ),
          Expanded(
            child: _MenuItem(
              label: 'Analyze',
              assetPath: 'assets/images/analyze_image.png',
              isActive: activeDestination == MenuDestination.analyze,
              onPressed: onAnalyze,
            ),
          ),
          Expanded(
            child: _MenuItem(
              label: 'Library',
              assetPath: 'assets/images/library_image.png',
              isActive: activeDestination == MenuDestination.library,
              onPressed: onLibrary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.assetPath,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x667C5CFF),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 24 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 0, 0),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}
