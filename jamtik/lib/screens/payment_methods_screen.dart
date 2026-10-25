import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/app_data.dart';
import '../models/settings_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  Future<void> _add() async {
    final card = await pushPage<PaymentCard>(context, const AddCardScreen());
    if (card == null || !mounted) return;
    setState(() {
      if (card.isDefault) {
        AppData.cards = [for (final c in AppData.cards) c.copyWith(isDefault: false)];
      }
      AppData.cards.add(card);
    });
  }

  Future<void> _makeDefault(PaymentCard card) async {
    try {
      await Api.setDefaultCard(card.id);
      if (!mounted) return;
      setState(() {
        AppData.cards = [for (final c in AppData.cards) c.copyWith(isDefault: c.id == card.id)];
      });
    } on BackendNotConnected catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _remove(PaymentCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JT.surface,
        title: Text('Remove card?', style: jtHeading(17)),
        content: Text('${card.label} will be removed from your account.', style: jtBody(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: jtBody(14, weight: FontWeight.w700, color: JT.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.removeCard(card.id);
      if (!mounted) return;
      setState(() => AppData.cards.removeWhere((c) => c.id == card.id));
    } on BackendNotConnected catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = AppData.cards;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      body: Column(
        children: [
          Expanded(
            child: cards.isEmpty
                ? const EmptyState(
                    icon: Icons.credit_card_off_outlined,
                    title: 'No cards yet',
                    message: 'Add a card to check out faster.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final c in cards)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                          decoration: BoxDecoration(
                            color: JT.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.isDefault ? JT.green : JT.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, color: JT.textMuted),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.label,
                                        style: jtBody(15, weight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('Expires ${c.expiry}', style: jtBody(12)),
                                  ],
                                ),
                              ),
                              if (c.isDefault) const TagChip('DEFAULT'),
                              PopupMenuButton<String>(
                                color: JT.surfaceAlt,
                                icon: const Icon(Icons.more_vert_rounded, color: JT.textMuted),
                                onSelected: (v) => v == 'default' ? _makeDefault(c) : _remove(c),
                                itemBuilder: (_) => [
                                  if (!c.isDefault)
                                    PopupMenuItem(
                                      value: 'default',
                                      child: Text('Make default', style: jtBody(14, color: Colors.white)),
                                    ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove', style: jtBody(14, color: JT.danger)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SafeArea(
              top: false,
              child: PrimaryButton(label: 'Add card', trailingIcon: Icons.add_rounded, onPressed: _add),
            ),
          ),
        ],
      ),
    );
  }
}