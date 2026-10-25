import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/checkout_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/host_profile_screen.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

/// Instagram-style event post used in the Home and Explore feeds.
class EventPostCard extends StatefulWidget {
  final Event event;
  const EventPostCard({super.key, required this.event});

  @override
  State<EventPostCard> createState() => _EventPostCardState();
}

class _EventPostCardState extends State<EventPostCard> {
  bool _liked = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: JT.surface,
        border: Border.all(color: JT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => pushPage<void>(context, HostProfileScreen(host: e.host)),
                  child: HostAvatar(e.host, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(e.host.name,
                                overflow: TextOverflow.ellipsis,
                                style: jtBody(12, weight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(width: 6),
                          if (e.host.verified)
                            const VerifiedCheck(size: 11)
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: JT.surfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Unverified host', style: jtBody(9, color: JT.textFaint)),
                            ),
                        ],
                      ),
                      Text(e.host.city, style: jtBody(10, color: JT.textFaint)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, size: 18, color: Colors.white70),
              ],
            ),
          ),
          // Flyer
          GestureDetector(
            onTap: () => pushPage<void>(context, EventDetailScreen(event: e)),
            child: Stack(
              children: [
                FlyerImage(url: e.flyerUrl, title: e.title),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: JT.yellow),
                        const SizedBox(width: 6),
                        Text(dateTimeShort(e.date), style: jtBody(11, weight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title.toUpperCase(), style: jtHeading(16, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${e.venue} • ${e.priceLabel}', style: jtBody(11, color: JT.textFaint)),
                    ],
                  ),
                ),
                if (e.isVerified) const TagChip('Verified Event'),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _liked = !_liked),
                  icon: Icon(_liked ? Icons.favorite : Icons.favorite_border_rounded,
                      color: _liked ? JT.danger : Colors.white, size: 22),
                ),
                Text(compact(e.likes + (_liked ? 1 : 0)), style: jtBody(12, color: Colors.white70)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => toast(context, 'Comments coming soon'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
                ),
                Text('${e.comments}', style: jtBody(12, color: Colors.white70)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _saved = !_saved),
                  icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border_rounded, size: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: e.isFree
                // Not in the mock-ups, but free events still need a way to claim a ticket.
                ? OutlinedButton(
                    onPressed: () => pushPage<void>(context, CheckoutScreen(event: e), fullscreen: true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: JT.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Get Free Ticket', style: jtBody(14, weight: FontWeight.w700, color: JT.green)),
                  )
                : PrimaryButton(
                    label: 'Get Tickets',
                    onPressed: () => pushPage<void>(context, CheckoutScreen(event: e), fullscreen: true),
                  ),
          ),
        ],
      ),
    );
  }
}
