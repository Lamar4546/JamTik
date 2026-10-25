import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'create_account_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    final user = auth.currentUser;
    if (session == null || user == null) return const LoginScreen();

    if (user.userMetadata?['account_complete'] != true) {
      final phone = user.phone ?? '';
      return CreateAccountScreen(
        token: session.accessToken,
        phone: phone.startsWith('+') || phone.isEmpty ? phone : '+$phone',
      );
    }
    return const AppShell();
  }
}