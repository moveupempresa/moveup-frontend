import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'confirm_email_change_screen.dart';

class ChangeEmailScreen extends StatefulWidget {
  final String token;

  const ChangeEmailScreen({super.key, required this.token});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newEmail = _emailController.text.trim();
    setState(() => _isLoading = true);
    try {
      await UserService.requestEmailChange(token: widget.token, newEmail: newEmail);
      if (!mounted) return;
      final updatedUser = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmEmailChangeScreen(token: widget.token, newEmail: newEmail),
        ),
      );
      if (updatedUser != null && mounted) {
        Navigator.of(context).pop(updatedUser);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar correo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ingresa el nuevo correo. Te enviaremos un código de verificación.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Nuevo correo electrónico'),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
