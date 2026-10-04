import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../widgets/contact_methods_editor.dart';
import 'home_screen.dart';

/// Mandatory, non-skippable step shown right after signup: every account
/// needs at least one contact method before reaching the rest of the app,
/// so a teacher (or anyone else) always has a way to reach the user.
class SetupContactMethodScreen extends StatelessWidget {
  final String token;
  final User user;
  final Profile profile;

  const SetupContactMethodScreen({
    super.key,
    required this.token,
    required this.user,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Not skippable: blocks the hardware/gesture back navigation too, not
    // just the AppBar's back arrow - otherwise it would still be possible
    // to back out to the login screen underneath without setting one.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Método de contacto'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Un último paso',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige al menos un método de contacto para que otros usuarios (por ejemplo, un profesor o el creador de un evento) puedan contactarte.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),
                ContactMethodsEditor(
                  token: token,
                  user: user,
                  profile: profile,
                  saveLabel: 'Continuar',
                  onSaved: (updatedUser, updatedProfile) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          user: updatedUser,
                          profile: updatedProfile,
                          token: token,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
