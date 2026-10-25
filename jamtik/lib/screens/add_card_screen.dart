import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api.dart';
import '../models/settings_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

String detectBrand(String digits) {
  if (digits.startsWith('4')) return 'Visa';
  if (digits.startsWith('34') || digits.startsWith('37')) return 'Amex';
  if (digits.startsWith('6011') || digits.startsWith('65')) return 'Discover';
  if (digits.length >= 2) {
    final two = int.tryParse(digits.substring(0, 2)) ?? 0;
    if (two >= 51 && two <= 55) return 'Mastercard';
  }
  if (digits.length >= 4) {
    final four = int.tryParse(digits.substring(0, 4)) ?? 0;
    if (four >= 2221 && four <= 2720) return 'Mastercard';
  }
  return 'Card';
}

bool luhnValid(String digits) {
  if (digits.length < 12) return false;
  var sum = 0;
  var alt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    var d = next.text.replaceAll(RegExp(r'\D'), '');
    final amex = d.startsWith('34') || d.startsWith('37');
    final maxLen = amex ? 15 : 19;
    if (d.length > maxLen) d = d.substring(0, maxLen);
    final cuts = amex ? const [4, 10] : const [4, 8, 12, 16];
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (cuts.contains(i)) b.write(' ');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    var d = next.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// Pops with the saved [PaymentCard] on success.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  bool _makeDefault = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvc.dispose();
    super.dispose();
  }

  String get _digits => _number.text.replaceAll(' ', '');
  String get _brand => detectBrand(_digits);

  int? get _month => int.tryParse(_expiry.text.split('/').first);
  int? get _year {
    final parts = _expiry.text.split('/');
    if (parts.length < 2 || parts[1].length != 2) return null;
    final yy = int.tryParse(parts[1]);
    return yy == null ? null : 2000 + yy;
  }

  bool get _expiryValid {
    final m = _month, y = _year;
    if (m == null || y == null || m < 1 || m > 12) return false;
    final now = DateTime.now();
    // A card is valid through the end of its expiry month.
    return DateTime(y, m + 1).isAfter(now);
  }

  bool get _cvcValid => _cvc.text.length == (_brand == 'Amex' ? 4 : 3);

  bool get _valid =>
      _name.text.trim().isNotEmpty && luhnValid(_digits) && _expiryValid && _cvcValid && !_saving;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final card = await Api.addCard(CardInput(
        holderName: _name.text.trim(),
        number: _digits,
        expMonth: _month!,
        expYear: _year!,
        cvc: _cvc.text,
        makeDefault: _makeDefault,
      ));
      if (!mounted) return;
      Navigator.pop(context, card);
    } on BackendNotConnected catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _digits;
    final numberBad = digits.length >= 13 && !luhnValid(digits);
    final expiryBad = _expiry.text.length == 5 && !_expiryValid;

    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const FieldLabel('Name on card'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.creditCardName],
            onChanged: (_) => setState(() {}),
            style: jtBody(15, color: Colors.white),
            decoration: const InputDecoration(hintText: 'As shown on the card'),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Card number'),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            autofillHints: const [AutofillHints.creditCardNumber],
            inputFormatters: [_CardNumberFormatter()],
            onChanged: (_) => setState(() {}),
            style: jtBody(15, color: Colors.white),
            decoration: InputDecoration(
              hintText: '0000 0000 0000 0000',
              errorText: numberBad ? 'Check the card number' : null,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(_brand == 'Card' ? '' : _brand,
                      style: jtBody(12, weight: FontWeight.w600, color: JT.textMuted)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Expiry'),
                    TextField(
                      controller: _expiry,
                      keyboardType: TextInputType.number,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      autofillHints: const [AutofillHints.creditCardExpirationDate],
                      inputFormatters: [_ExpiryFormatter()],
                      onChanged: (_) => setState(() {}),
                      style: jtBody(15, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        errorText: expiryBad ? 'Card has expired' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('CVC'),
                    TextField(
                      controller: _cvc,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      autofillHints: const [AutofillHints.creditCardSecurityCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: jtBody(15, color: Colors.white),
                      decoration: const InputDecoration(hintText: '123'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _makeDefault,
            onChanged: (v) => setState(() => _makeDefault = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: JT.green,
            checkColor: Colors.black,
            title: Text('Set as default payment method', style: jtBody(14, color: Colors.white)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: jtBody(12, color: JT.danger)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save card',
            glow: true,
            height: 52,
            onPressed: _valid ? _save : null,
          ),
        ],
      ),
    );
  }
}