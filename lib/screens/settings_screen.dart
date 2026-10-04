import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import 'settings/account_screen.dart';
import 'settings/appearance_screen.dart';
import 'settings/contact_methods_screen.dart';
import 'settings/pro_plan_screen.dart';

/// Pops with `(updatedUser, updatedProfile)` - either may be null if that
/// sub-screen's edit didn't touch it - so [ProfileScreen] can refresh
/// whichever part actually changed.
class SettingsScreen extends StatelessWidget {
  final String token;
  final User user;
  final Profile profile;

  const SettingsScreen({
    super.key,
    required this.token,
    required this.user,
    required this.profile,
  });

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
                Navigator.of(context).pop((updatedUser, null));
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
                Navigator.of(context).pop((updatedUser, null));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone_outlined),
            title: const Text('Métodos de contacto'),
            subtitle: profile.contactMethods.hasAny
                ? null
                : const Text('Añade al menos uno'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactMethodsScreen(
                    token: token,
                    user: user,
                    profile: profile,
                  ),
                ),
              );
              if (result != null && context.mounted) {
                final (updatedUser, updatedProfile) = result as (User, Profile);
                Navigator.of(context).pop((updatedUser, updatedProfile));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Apariencia'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
        ],
      ),
    );
  }
}
