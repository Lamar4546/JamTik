import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'checkout_screen.dart';
import 'host_profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _expanded = false;
  bool _following = false;
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero
          SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlyerImage(url: e.flyerUrl, title: e.title, aspectRatio: 1.2),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  child: _circleButton(Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
                ),
                Positioned(
                  top: top + 8,
                  right: 12,
                  child: Row(
                    children: [
                      _circleButton(_liked ? Icons.favorite : Icons.favorite_border_rounded,
                          () => setState(() => _liked = !_liked),
                          color: _liked ? JT.danger : Colors.white),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (e.isVerified) const TagChip('VERIFIED', filled: true),
                          if (e.isVerified && e.spotsLeft != null) const SizedBox(width: 6),
                          if (e.spotsLeft != null) TagChip('ONLY ${e.spotsLeft} LEFT', color: JT.yellow),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(e.title.toUpperCase(), style: jtHeading(24, weight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(Icons.calendar_month_rounded, JT.green, 'Date & Time',
                          '${monthAbbr(e.date)[0]}${monthAbbr(e.date).substring(1).toLowerCase()} ${e.date.day} • ${timeLabel(e.date, padded: false).replaceAll(':00', '')}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _infoTile(Icons.location_on_rounded, JT.yellow, 'Venue', e.venue)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('About the Event', style: jtHeading(16)),
                const SizedBox(height: 8),
                Text(e.description,
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: jtBody(13).copyWith(height: 1.5)),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_expanded ? 'Show less' : 'Read more', style: jtBody(13, color: JT.green)),
                  ),
                ),
                const SizedBox(height: 20),
                _hostCard(e),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket Tiers', style: jtHeading(16)),
                    Text('Limit: ${e.maxPerPerson} per person',
                        style: jtBody(11, color: JT.textFaint).copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 12),
                for (final t in e.tiers) _TierRow(tier: t),
                if (e.merch.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Official Merch', style: jtHeading(16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: e.merch.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final m = e.merch[i];
                        return SizedBox(
                          width: 98,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PlaceholderTile(size: 98, imageUrl: m.imageUrl),
                              const SizedBox(height: 6),
                              Text(m.name, style: jtBody(11, weight: FontWeight.w500, color: Colors.white)),
                              Text(jmd(m.price), style: jtBody(10, color: JT.green)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: JT.bg,
          border: Border(top: BorderSide(color: JT.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starts from', style: jtBody(10, color: JT.textFaint)),
                  Text(e.isFree ? 'Free' : jmd(e.startingPrice), style: jtHeading(20, color: JT.yellow)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: PrimaryButton(
                  label: e.isFree ? 'Get Free Ticket' : 'Buy Tickets',
                  glow: true,
                  onPressed: () => pushPage<void>(context, CheckoutScreen(event: e), fullscreen: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color color = Colors.white}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: color),
        ),
      );

  Widget _infoTile(IconData icon, Color iconColor, String label, String value) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JT.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JT.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 8),
            Text(label, style: jtBody(10, color: JT.textFaint)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: jtBody(13, weight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );

  Widget _hostCard(Event e) => GestureDetector(
        onTap: () => pushPage<void>(context, HostProfileScreen(host: e.host)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: JT.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JT.border),
          ),
          child: Row(
            children: [
              HostAvatar(e.host, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOSTED BY', style: jtBody(9, color: JT.textFaint).copyWith(letterSpacing: 1)),
                    Row(
                      children: [
                        Flexible(
                          child: Text(e.host.name,
                              overflow: TextOverflow.ellipsis,
                              style: jtBody(13, weight: FontWeight.w700, color: Colors.white)),
                        ),
                        if (e.host.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedCheck(size: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _following = !_following),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: JT.green),
                  backgroundColor: _following ? JT.green.withValues(alpha: 0.12) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(_following ? 'FOLLOWING' : 'FOLLOW',
                    style: jtBody(11, weight: FontWeight.w700, color: JT.green)),
              ),
            ],
          ),
        ),
      );
}

class _TierRow extends StatelessWidget {
  final TicketTier tier;
  const _TierRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    final out = !tier.available;
    return Opacity(
      opacity: out ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: out ? JT.surfaceDim : JT.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: out ? JT.border : JT.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.name,
                      style: jtBody(14, weight: FontWeight.w600, color: out ? JT.textMuted : Colors.white)),
                  const SizedBox(height: 2),
                  Text(tier.price == 0 ? 'Free' : jmd(tier.price), style: jtBody(11, color: JT.textFaint)),
                ],
              ),
            ),
            out
                ? const TagChip('SOLD OUT', color: JT.danger)
                : Text('AVAILABLE', style: jtBody(10, weight: FontWeight.w600, color: JT.green)),
          ],
        ),
      ),
    );
  }
}
