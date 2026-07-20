import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/auth_storage_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

enum _SessionStatus { loading, authenticated, unauthenticated }

/// Shown first on every cold start. Tries to resume a previously saved
/// session before falling back to [LoginScreen].
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  _SessionStatus _status = _SessionStatus.loading;
  User? _user;
  Profile? _profile;
  String? _token;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await AuthStorageService.loadToken();
    if (token == null) {
      if (mounted) setState(() => _status = _SessionStatus.unauthenticated);
      return;
    }

    try {
      final session = await AuthService.getCurrentSession(token: token);
      if (mounted) {
        setState(() {
          _user = session.user;
          _profile = session.profile;
          _token = token;
          _status = _SessionStatus.authenticated;
        });
      }
    } on SessionExpiredException {
      await AuthStorageService.clearToken();
      if (mounted) setState(() => _status = _SessionStatus.unauthenticated);
    } catch (_) {
      // Network hiccup or server error: keep the token so the next launch
      // can retry, but let the user log in manually for now.
      if (mounted) setState(() => _status = _SessionStatus.unauthenticated);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _SessionStatus.unauthenticated:
        return const LoginScreen();
      case _SessionStatus.authenticated:
        return HomeScreen(user: _user!, profile: _profile!, token: _token!);
    }
  }
}
