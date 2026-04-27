import 'dart:async';

import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool showHome = false;
  bool visible = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => visible = true);
      }
    });
    timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => showHome = true);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: showHome ? const HomeScreen() : _SplashContent(visible: visible),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: visible ? 1 : 0.96,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.13),
                    border: Border.all(color: AppColors.accent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '86',
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: 'monospace',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '8086 Assembly Simulator',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fetch - Decode - Execute',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
