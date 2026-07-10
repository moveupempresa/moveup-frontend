import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../login_screen.dart';
import 'change_email_screen.dart';

class AccountScreen extends StatefulWidget {
  final String token;
  final User user;

  const AccountScreen({super.key, required this.token, required this.user});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _automaticReminders = true;
  bool _isChangingUsername = false;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changeUsername() async {
    final controller = TextEditingController(text: _user.username);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar nombre de usuario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de usuario'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final newUsername = controller.text.trim();
    if (newUsername == _user.username) return;

    setState(() => _isChangingUsername = true);
    try {
      final updatedUser = await UserService.changeUsername(
        token: widget.token,
        username: newUsername,
      );
      if (!mounted) return;
      setState(() => _user = updatedUser);
      Navigator.of(context).pop(_user);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isChangingUsername = false);
    }
  }

  Future<void> _changeEmail() async {
    final updatedUser = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeEmailScreen(token: widget.token),
      ),
    );
    if (updatedUser != null && mounted) {
      setState(() => _user = updatedUser);
      Navigator.of(context).pop(_user);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Estás seguro? Esta acción es irreversible y eliminará todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await UserService.deleteAccount(token: widget.token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: ListView(
        children: [
          _sectionHeader('Información de cuenta'),
          ListTile(
            leading: _isChangingUsername
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_outline),
            title: const Text('Cambiar nombre de usuario'),
            subtitle: Text(_user.username),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isChangingUsername ? null : _changeUsername,
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Cambiar correo electrónico'),
            subtitle: Text(_user.email),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeEmail,
          ),
          const Divider(height: 32),
          _sectionHeader('Notificaciones'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones push'),
            subtitle: const Text('Recibe alertas en tu dispositivo'),
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.mark_email_unread_outlined),
            title: const Text('Correos electrónicos'),
            subtitle: const Text('Recibe novedades por correo'),
            value: _emailNotifications,
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_outlined),
            title: const Text('Recordatorios automáticos'),
            subtitle: const Text('Aviso antes de tus clases y eventos'),
            value: _automaticReminders,
            onChanged: (val) => setState(() => _automaticReminders = val),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: _logout,
              child: const Text('Cerrar sesión'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: _deleteAccount,
              child: const Text('Eliminar cuenta'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
