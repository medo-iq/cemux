import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/controllers/cpu_controller.dart';
import 'app/screens/splash_screen.dart';
import 'config/app_theme.dart';
import 'features/editor/editor_controller.dart';

void main() {
  runApp(const CemuXApp());
}

class CemuXApp extends StatelessWidget {
  const CemuXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '8086 Assembly Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialBinding: BindingsBuilder(() {
        Get.put(CpuController());
        Get.put(EditorController());
      }),
      home: const SplashScreen(),
    );
  }
}
