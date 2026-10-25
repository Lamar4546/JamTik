import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/session.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'app_shell.dart';
import 'login_screen.dart';

/// Shown once, right after a new phone number is verified.
class CreateAccountScreen extends StatefulWidget {
  /// Token for the verified phone. Only saved to storage once the account is complete.
  final String token;
  final String phone; // E.164, e.g. +18765550123
  const CreateAccountScreen({super.key, required this.token, required this.phone});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    if (_password.text.length < 8) return 'Password must be at least 8 characters';
    if (_password.text != _confirm.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      Session.token = widget.token; // lets the API call be authenticated
      await Api.completeAccount(email: _email.text.trim(), password: _password.text);
      await Session.save(widget.token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
        (_) => false,
      );
    } on BackendNotConnected catch (e) {
      Session.token = null;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _back() {
    Session.token = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _back),
          title: const Text('Create your account'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Almost there', style: jtHeading(24, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Your tickets will be linked to ${widget.phone} and your email, so you can always find them.',
              style: jtBody(13).copyWith(height: 1.5),
            ),
            const SizedBox(height: 28),
            const FieldLabel('Email'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              style: jtBody(15, color: Colors.white),
              decoration: const InputDecoration(hintText: 'you@example.com'),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Password'),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              style: jtBody(15, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20, color: JT.textFaint),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Confirm password'),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              style: jtBody(15, color: Colors.white),
              decoration: const InputDecoration(hintText: 'Re-enter password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: jtBody(12, color: JT.danger)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _loading ? 'Please wait…' : 'Create account',
              glow: true,
              height: 52,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}