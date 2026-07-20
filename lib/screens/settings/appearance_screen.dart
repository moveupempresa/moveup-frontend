import 'package:flutter/material.dart';

import '../../services/theme_service.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return ListView(
            children: [
              RadioListTile<ThemeMode>(
                secondary: const Icon(Icons.light_mode_outlined),
                title: const Text('Claro'),
                value: ThemeMode.light,
                groupValue: mode,
                onChanged: (value) => ThemeService.setThemeMode(value!),
              ),
              RadioListTile<ThemeMode>(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Oscuro'),
                value: ThemeMode.dark,
                groupValue: mode,
                onChanged: (value) => ThemeService.setThemeMode(value!),
              ),
            ],
          );
        },
      ),
    );
  }
}
