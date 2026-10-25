import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

/// Step 1 of 3: pick tickets. Steps 2 (payment) and 3 (confirmation) are TODO.
class CheckoutScreen extends StatefulWidget {
  final Event event;
  const CheckoutScreen({super.key, required this.event});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Map<String, int> _qty = {};

  Event get _e => widget.event;
  int get _count => _qty.values.fold(0, (a, b) => a + b);
  int get _total => _e.tiers.fold(0, (sum, t) => sum + t.price * (_qty[t.id] ?? 0));

  String get _summaryNames {
    final names = _e.tiers.where((t) => (_qty[t.id] ?? 0) > 0).map((t) => t.name).toList();
    return names.isEmpty ? 'No tickets selected' : names.join(', ');
  }

  bool _canAdd(TicketTier t) {
    final q = _qty[t.id] ?? 0;
    if (!t.available || _count >= _e.maxPerPerson) return false;
    if (t.remaining != null && q >= t.remaining!) return false;
    return true;
  }

  void _change(TicketTier t, int delta) {
    final q = _qty[t.id] ?? 0;
    if (delta > 0 && !_canAdd(t)) return;
    if (delta < 0 && q == 0) return;
    setState(() => _qty[t.id] = q + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: StepBar(total: 3, current: 0),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: JT.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const PlaceholderTile(size: 58, radius: 12),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_e.title.toUpperCase(), style: jtBody(14, weight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text('${monthAbbr(_e.date)[0]}${monthAbbr(_e.date).substring(1).toLowerCase()} ${_e.date.day} • ${_e.venue}',
                              style: jtBody(12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Select Tickets', style: jtHeading(17)),
                const SizedBox(height: 14),
                for (final t in _e.tiers.where((t) => t.available)) _tierCard(t),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: JT.border))),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Total', style: jtBody(10, color: JT.textFaint)),
                          Text(jmd(_total), style: jtHeading(22, color: JT.yellow)),
                        ],
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$_count ${_count == 1 ? 'Ticket' : 'Tickets'}', style: jtBody(10, color: JT.textMuted)),
                            Text(_summaryNames,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: jtBody(11, weight: FontWeight.w500, color: JT.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _total == 0 && _count > 0 ? 'Confirm Free Ticket' : 'Continue to Payment',
                    glow: true,
                    height: 52,
                    onPressed: _count == 0
                        ? null
                        : () {
                            // TODO: step 2 (payment) -> step 3 (confirmation), then add the
                            // purchased tickets to the user's wallet.
                            toast(context, 'Payment step coming next');
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(TicketTier t) {
    final q = _qty[t.id] ?? 0;
    final selected = q > 0;
    return Opacity(
      opacity: selected ? 1 : 0.7,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? JT.surface : JT.surfaceDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? JT.green : JT.border),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: jtBody(16, weight: FontWeight.w600, color: Colors.white)),
                      if (t.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(t.description, style: jtBody(12)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t.price == 0 ? 'Free' : jmd(t.price),
                        style: jtHeading(16, color: selected ? JT.green : JT.textMuted)),
                    if (t.price > 0) Text('Per ticket', style: jtBody(10, color: JT.textFaint)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.remaining != null && t.remaining! <= 20
                      ? 'Only ${t.remaining} left'
                      : 'Max ${_e.maxPerPerson} per person',
                  style: jtBody(11, color: JT.yellow),
                ),
                Row(
                  children: [
                    _stepper(Icons.remove, q > 0 ? () => _change(t, -1) : null, false),
                    SizedBox(
                      width: 40,
                      child: Text('$q', textAlign: TextAlign.center, style: jtHeading(16)),
                    ),
                    _stepper(Icons.add, _canAdd(t) ? () => _change(t, 1) : null, true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(IconData icon, VoidCallback? onTap, bool accent) {
    final enabled = onTap != null;
    final color = enabled ? (accent ? JT.green : Colors.white70) : JT.textFaint.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: accent && enabled ? 1 : 0.6)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
