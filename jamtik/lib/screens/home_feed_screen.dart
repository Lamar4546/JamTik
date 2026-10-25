import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/event_post_card.dart';
import '../widgets/shared.dart';
import 'create_event_screen.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: const JamTikWordmark(size: 16),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: JT.border),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => toast(context, 'Notifications coming soon'),
                icon: const Icon(Icons.favorite_border_rounded),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: JT.green, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => toast(context, 'Messages coming soon'),
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _StoriesRow(),
          if (AppData.events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: EmptyState(
                icon: Icons.celebration_outlined,
                title: 'No events yet',
                message: 'Events from hosts will show up here. Tap + to host one.',
              ),
            ),
          for (final e in AppData.events) EventPostCard(event: e),
        ],
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    // Categories double as filters for the feed.
    const labels = ['Parties', 'Concerts', 'Festivals', 'Dancehall'];
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          RingAvatar(
            label: 'Host',
            onTap: () => pushPage<void>(context, const CreateEventScreen(), fullscreen: true),
            child: const Icon(Icons.add, color: JT.green),
          ),
          for (var i = 0; i < labels.length; i++) ...[
            const SizedBox(width: 14),
            RingAvatar(
              label: labels[i],
              ring: i.isEven ? JT.yellow : JT.green,
              onTap: () => toast(context, 'Filter: ${labels[i]}'),
              child: Text(labels[i][0], style: jtHeading(18)),
            ),
          ],
        ],
      ),
    );
  }
}
