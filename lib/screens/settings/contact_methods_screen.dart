import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/user.dart';
import '../../widgets/contact_methods_editor.dart';

/// Lets the user review/change which contact methods show on their
/// profile (and, for creators, on their events' cards).
class ContactMethodsScreen extends StatelessWidget {
  final String token;
  final User user;
  final Profile profile;

  const ContactMethodsScreen({
    super.key,
    required this.token,
    required this.user,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de contacto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige cómo pueden contactarte. Esta información aparece en tu perfil y, si creas eventos, en sus cards.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),
              ContactMethodsEditor(
                token: token,
                user: user,
                profile: profile,
                onSaved: (updatedUser, updatedProfile) {
                  Navigator.of(context).pop((updatedUser, updatedProfile));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
