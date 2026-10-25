import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import '../widgets/event_post_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _chips = ['All', 'Parties', 'Concerts', 'Festivals', 'Dancehall', 'Free'];
  String _chip = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // TODO: categories aren't on the Event model yet; only search + "Free" filter work.
    final results = AppData.events.where((e) {
      final q = _query.toLowerCase();
      final matches = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q) ||
          e.host.name.toLowerCase().contains(q);
      final free = _chip != 'Free' || e.isFree;
      return matches && free;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: jtBody(14, color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search events, venues, hosts',
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: JT.textFaint),
            contentPadding: EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _chips[i];
                final on = c == _chip;
                return GestureDetector(
                  onTap: () => setState(() => _chip = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? JT.green : JT.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(c, style: jtBody(12, weight: FontWeight.w600, color: on ? Colors.black : JT.textMuted)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(icon: Icons.search_off_rounded, title: 'No events found')
                : ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [for (final e in results) EventPostCard(event: e)],
                  ),
          ),
        ],
      ),
    );
  }
}
