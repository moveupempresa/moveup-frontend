import 'package:flutter/material.dart';

import '../models/user.dart';
import 'settings/account_screen.dart';
import 'settings/appearance_screen.dart';
import 'settings/pro_plan_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String token;
  final User user;

  const SettingsScreen({super.key, required this.token, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Cuenta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final updatedUser = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AccountScreen(token: token, user: user),
                ),
              );
              if (updatedUser != null && context.mounted) {
                Navigator.of(context).pop(updatedUser);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Plan Pro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final updatedUser = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProPlanScreen(
                    token: token,
                    subscriptionPlan: user.subscriptionPlan,
                  ),
                ),
              );
              if (updatedUser != null && context.mounted) {
                Navigator.of(context).pop(updatedUser);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Apariencia'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
