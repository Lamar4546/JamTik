import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'create_account_screen.dart';
import  '../data/session.dart';
import '../data/api.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _sendOtp() async {
    if (_digits.length != 7) {
      setState(() => _error = 'Enter your 7-digit number');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await Api.sendOtp('+1876$_digits');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpSent = true;
      });
    } on BackendNotConnected catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

    Future<void> _verify() async {
    if (_otp.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final phone = '+1876$_digits';
    try {
      final result = await Api.verifyOtp(phone, _otp.text);
      if (!mounted) return;
      if (result.isNewAccount) {
        // Not saved yet: the session is only stored once email + password are set.
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => CreateAccountScreen(token: result.token, phone: phone),
        ));
      } else {
        await Session.save(result.token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
        );
      }
    } on BackendNotConnected catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03200E), Colors.black, Color(0xFF1F1B05)],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: JT.green.withValues(alpha: 0.4), blurRadius: 30)],
                    ),
                    // TODO: replace with Image.asset('assets/logo.png')
                    child: const Icon(Icons.confirmation_number_rounded, size: 54, color: JT.yellow),
                  ),
                  const SizedBox(height: 10),
                  const JamTikWordmark(size: 28, showIcon: false),
                  const SizedBox(height: 4),
                  Text("Jamaica's Pulse for Events", style: jtBody(12, color: Colors.white70)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_otpSent ? 'Enter your code' : 'Get Your Pass',
                            style: jtHeading(20, color: JT.green)),
                        const SizedBox(height: 4),
                        Text(
                          _otpSent
                              ? 'We sent a 6-digit code to +876 ${_phone.text}.'
                              : 'Enter your phone to join the vibe.',
                          style: jtBody(12),
                        ),
                        const SizedBox(height: 16),
                        if (!_otpSent) _phoneField() else _otpField(),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: jtBody(12, color: JT.danger)),
                        ],
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: _loading ? 'Please wait…' : (_otpSent ? 'Verify' : 'Send OTP'),
                          trailingIcon: _otpSent || _loading ? null : Icons.send_rounded,
                          glow: true,
                          onPressed: _loading ? null : (_otpSent ? _verify : _sendOtp),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: _otpSent
                              ? TextButton(
                                  onPressed: () => setState(() {
                                    _otpSent = false;
                                    _otp.clear();
                                    _error = null;
                                  }),
                                  child: Text('Use a different number', style: jtBody(12, color: JT.green)),
                                )
                              : Text('One account • One number • All the vibes',
                                  style: jtBody(10, color: JT.textFaint)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('By entering you agree to the jamTik Terms & Privacy',
                      textAlign: TextAlign.center, style: jtBody(10, color: JT.textFaint)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneField() => TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        inputFormatters: [_PhoneFormatter()],
        style: jtBody(16, color: Colors.white),
        decoration: InputDecoration(
          hintText: '000-0000',
          fillColor: JT.surfaceDim,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Center(
              widthFactor: 1,
              child: Text('+876', style: jtBody(13, color: JT.textFaint)),
            ),
          ),
        ),
      );

  Widget _otpField() => TextField(
        controller: _otp,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: jtHeading(22).copyWith(letterSpacing: 8),
        decoration: const InputDecoration(hintText: '••••••', counterText: '', fillColor: JT.surfaceDim),
      );
}

/// Formats Jamaican local numbers as 000-0000.
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 7) d = d.substring(0, 7);
    final text = d.length > 3 ? '${d.substring(0, 3)}-${d.substring(3)}' : d;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
