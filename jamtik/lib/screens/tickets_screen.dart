import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/api.dart';
import '../data/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

/// Max amount a ticket may be resold above its original price.
const kMaxResaleMarkup = 5000;

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tickets = AppData.myTickets;
    final current = tickets.isEmpty ? null : tickets[_selected];
    final upcoming = [
      for (var i = 0; i < tickets.length; i++)
        if (i != _selected) tickets[i]
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('My Tickets', style: jtHeading(22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: JT.surfaceAlt),
              onPressed: () => toast(context, 'Past tickets coming soon'),
              icon: const Icon(Icons.history_rounded, size: 18),
            ),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: JT.border)),
      ),
      body: current == null
          ? const EmptyState(icon: Icons.confirmation_number_outlined, title: 'No tickets yet', message: 'Tickets you buy or receive will appear here.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TicketCard(ticket: current),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _action(Icons.send_rounded, 'Send to Friend', JT.green,
                          () => _sendSheet(current)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _action(Icons.swap_horiz_rounded, 'Trade', JT.yellow,
                          // TODO: trade flow (pick friend + the ticket they offer).
                          () => toast(context, 'Trades coming soon')),
                    ),
                    if (!current.isFree) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _action(Icons.sell_rounded, 'Resell', JT.green, () => _resellSheet(current)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    current.isFree
                        ? 'Free tickets cannot be resold'
                        : 'Max resale: ${jmd(kMaxResaleMarkup)} above original price',
                    style: jtBody(10, color: JT.textFaint).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('UPCOMING', style: jtBody(12, weight: FontWeight.w600).copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  for (final t in upcoming)
                    _upcomingRow(t, () => setState(() => _selected = tickets.indexOf(t))),
                ],
              ],
            ),
    );
  }

  Widget _action(IconData icon, String label, Color iconColor, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111A14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JT.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: jtBody(11, weight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _upcomingRow(OwnedTicket t, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: JT.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JT.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: JT.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(monthAbbr(t.event.date), style: jtBody(9, color: JT.textFaint)),
                    Text(t.event.date.day.toString().padLeft(2, '0'), style: jtHeading(17)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.event.title.toUpperCase(),
                        style: jtBody(13, weight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${t.event.venue} • 1 Ticket', style: jtBody(11, color: JT.textFaint)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: JT.textFaint),
            ],
          ),
        ),
      );

  void _sendSheet(OwnedTicket t) {
    final ctrl = TextEditingController();
    showJTSheet<void>(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send to a friend', style: jtHeading(18)),
          const SizedBox(height: 4),
          Text("They'll need a jamTik account tied to this number.", style: jtBody(12)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), LengthLimitingTextInputFormatter(8)],
            style: jtBody(16, color: Colors.white),
            decoration: const InputDecoration(prefixText: '+876  ', hintText: '000-0000'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Send ticket',
            onPressed: () async {
              try {
                await Api.sendTicket(orderId: t.orderId, toPhone: '+1876${ctrl.text.replaceAll('-', '')}');
                if (!mounted) return;
                Navigator.pop(ctx);
                toast(context, 'Ticket sent');
              } on BackendNotConnected catch (e) {
                if (mounted) toast(context, e.message);
              }
            },
          ),
        ],
      );
    });
  }

  void _resellSheet(OwnedTicket t) {
    final ctrl = TextEditingController(text: t.tier.price.toString());
    final maxPrice = t.tier.price + kMaxResaleMarkup;
    String? error;
    showJTSheet<void>(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resell ticket', style: jtHeading(18)),
            const SizedBox(height: 4),
            Text('Original price ${jmd(t.tier.price)}. You can list for up to ${jmd(maxPrice)}.',
                style: jtBody(12)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: jtBody(16, color: Colors.white),
              decoration: InputDecoration(prefixText: 'J\$ ', errorText: error),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'List for resale',
              onPressed: () async {
                final price = int.tryParse(ctrl.text) ?? 0;
                if (price <= 0 || price > maxPrice) {
                  setSheet(() => error = 'Enter a price up to ${jmd(maxPrice)}');
                  return;
                }
                try {
                  // The backend must re-check the cap too; never trust the client.
                  await Api.listForResale(orderId: t.orderId, price: price);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  toast(context, 'Listed for ${jmd(price)}');
                } on BackendNotConnected catch (e) {
                  setSheet(() => error = e.message);
                }
              },
            ),
          ],
        );
      });
    });
  }
}

class _TicketCard extends StatelessWidget {
  final OwnedTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final e = ticket.event;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: JT.green.withValues(alpha: 0.18), blurRadius: 40)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(ticket.tier.name.toUpperCase(),
                          style: jtBody(9, weight: FontWeight.w700, color: const Color(0xFF15803D))),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_rounded, size: 14, color: JT.yellow),
                        const SizedBox(width: 4),
                        Text('jamTik', style: jtHeading(13, color: const Color(0xFF111827))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(e.title.split(':').first.toUpperCase(),
                    style: jtHeading(26, weight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text('${e.venue} • ${e.city}'.toUpperCase(),
                    style: jtBody(11, color: const Color(0xFF6B7280))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _field('DATE', '${weekday(e.date)}, ${monthAbbr(e.date)} ${e.date.day} ${e.date.year}')),
                    Expanded(child: _field('TIME', timeLabel(e.date))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field('GUEST', ticket.guest)),
                    Expanded(child: _field('ORDER ID', ticket.orderId)),
                  ],
                ),
              ],
            ),
          ),
          // Perforation
          SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: DashedLine(),
                  ),
                ),
                Positioned(left: -12, top: 0, child: _notch()),
                Positioned(right: -12, top: 0, child: _notch()),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  // Standard dark-on-light QR: inverted codes (as in the mock-up)
                  // fail on many scanners.
                  child: QrImageView(
                    data: ticket.orderId,
                    size: 170,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Text('SCAN AT ENTRANCE',
                    style: jtBody(10, color: const Color(0xFF9CA3AF)).copyWith(letterSpacing: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notch() => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(color: JT.bg, shape: BoxShape.circle),
      );

  Widget _field(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: jtBody(9, color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value, style: jtBody(14, weight: FontWeight.w700, color: const Color(0xFF111827))),
        ],
      );
}

String weekday(DateTime d) => const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d.weekday - 1];
