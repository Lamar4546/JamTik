import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'event_detail_screen.dart';

/// Grid of events, used for Saved and Archive.
class EventGridScreen extends StatelessWidget {
  final String title;
  final List<Event> events;
  final String emptyTitle;
  final String? emptyMessage;
  const EventGridScreen({
    super.key,
    required this.title,
    required this.events,
    required this.emptyTitle,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: events.isEmpty
          ? EmptyState(icon: Icons.bookmark_border_rounded, title: emptyTitle, message: emptyMessage)
          : GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: events.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (ctx, i) {
                final e = events[i];
                return GestureDetector(
                  onTap: () => pushPage<void>(ctx, EventDetailScreen(event: e)),
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FlyerImage(url: e.flyerUrl, title: e.title, aspectRatio: 0.75),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          right: 6,
                          child: Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jtBody(11, weight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}