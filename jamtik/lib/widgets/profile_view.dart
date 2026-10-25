import 'package:flutter/material.dart';

import '../data/api.dart';
import '../models/models.dart';
import '../screens/event_detail_screen.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

/// TikTok-style profile header with Instagram-style highlights.
/// Used for your own profile (isOwner: true) and for other hosts.
class ProfileView extends StatefulWidget {
  final Host host;
  final bool isOwner;
  final List<Highlight> highlights;
  final List<Event> upcoming;
  final List<Event> past;
  final List<Event> tagged;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onEditProfile;
  final VoidCallback? onNewHighlight;
  final VoidCallback? onOpenMerch;
  final ValueChanged<Highlight>? onOpenHighlight;

  const ProfileView({
    super.key,
    required this.host,
    required this.isOwner,
    this.highlights = const [],
    this.upcoming = const [],
    this.past = const [],
    this.tagged = const [],
    this.onBack,
    this.onMenu,
    this.onEditProfile,
    this.onNewHighlight,
    this.onOpenMerch,
    this.onOpenHighlight,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _following = false;
  bool _busy = false;
  int _tab = 0; // 0 upcoming, 1 past, 2 tagged

  Future<void> _toggleFollow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Api.setFollow(widget.host.id, !_following);
      if (mounted) setState(() => _following = !_following);
    } on BackendNotConnected catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.host;
    final events = [widget.upcoming, widget.past, widget.tagged][_tab];
    const emptyTitles = ['No upcoming events', 'No past events', 'Nothing tagged yet'];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(context),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: _actions()),
        if (h.bio.isNotEmpty || h.website != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (h.bio.isNotEmpty)
                  Text(h.bio, style: jtBody(14, color: Colors.white).copyWith(height: 1.4)),
                if (h.website != null) ...[
                  const SizedBox(height: 4),
                  Text(h.website!, style: jtBody(14, weight: FontWeight.w700, color: Colors.white)),
                ],
              ],
            ),
          ),
        _highlightsRow(),
        const SizedBox(height: 14),
        Row(children: [
          _tabIcon(0, Icons.calendar_month_rounded),
          _tabIcon(1, Icons.history_rounded),
          _tabIcon(2, Icons.sell_rounded),
        ]),
        const Divider(height: 1, color: JT.border),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 56, bottom: 40),
            child: EmptyState(icon: Icons.event_busy_outlined, title: emptyTitles[_tab]),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(compact(e.likes),
                                style: jtBody(12, weight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------- header ----------

  Widget _header(BuildContext context) {
    final h = widget.host;
    final top = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 320 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _banner(h),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x80000000), Color(0x00000000), Color(0xFF000000)],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: top + 6,
            left: 12,
            right: 12,
            child: Row(
              children: [
                if (widget.onBack != null)
                  GestureDetector(
                    onTap: widget.onBack,
                    child: _circle(Icons.arrow_back_rounded),
                  )
                else
                  const SizedBox(width: 38),
                const Spacer(),
                if (widget.isOwner) ...[
                  _topIcon(Icons.ios_share_rounded, () => toast(context, 'Sharing coming soon')),
                  _topIcon(Icons.menu_rounded, widget.onMenu ?? () {}),
                ] else ...[
                  _topIcon(Icons.notifications_none_rounded, () => toast(context, 'Notifications coming soon')),
                  _topIcon(Icons.ios_share_rounded, () => toast(context, 'Sharing coming soon')),
                ],
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: jtHeading(32, weight: FontWeight.w800).copyWith(height: 1.05)),
                      if (h.handle.isNotEmpty || h.verified || h.badgeLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _handleRow(h),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat('${h.events}', 'Events'),
                          const SizedBox(width: 28),
                          _stat(compact(h.followers), 'Followers'),
                          const SizedBox(width: 28),
                          _stat(compact(h.following), 'Following'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: HostAvatar(h, size: 78),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(Host h) {
    Widget fallback() => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E2B), Color(0xFF0B0B0B), Color(0xFF3F3A06)],
            ),
          ),
        );
    if (h.bannerUrl == null) return fallback();
    return Image.network(h.bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
  }

  Widget _handleRow(Host h) {
    final style = jtBody(14, color: Colors.white70);
    final parts = <Widget>[];
    if (h.handle.isNotEmpty) {
      parts.add(Flexible(child: Text('@${h.handle}', overflow: TextOverflow.ellipsis, style: style)));
    }
    if (h.verified) {
      parts.add(const SizedBox(width: 6));
      parts.add(const VerifiedCheck(size: 14));
    }
    if (h.badgeLabel.isNotEmpty) {
      final sep = (h.handle.isNotEmpty || h.verified) ? '  ·  ' : '';
      parts.add(Text('$sep${h.badgeLabel}', style: style));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }

  Widget _stat(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: jtHeading(20)),
          Text(label, style: jtBody(13, color: Colors.white60)),
        ],
      );

  Widget _circle(IconData icon) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.white),
      );

  Widget _topIcon(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(onTap: onTap, child: _circle(icon)),
      );

  // ---------- buttons ----------

  Widget _actions() {
    if (widget.isOwner) {
      return Row(
        children: [
          Expanded(
            child: _pill('Edit profile', widget.onEditProfile ?? () => toast(context, 'Edit profile coming soon')),
          ),
          const SizedBox(width: 8),
          Expanded(child: _pill('Share profile', () => toast(context, 'Sharing coming soon'))),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _busy ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _following ? JT.surfaceAlt : JT.green,
                foregroundColor: _following ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_following ? 'Following' : 'Follow',
                  style: jtBody(15, weight: FontWeight.w700, color: _following ? Colors.white : Colors.black)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 5, child: _pill('Message', () => toast(context, 'Messages coming soon'), height: 46)),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          height: 46,
          child: ElevatedButton(
            onPressed: () => toast(context, 'Coming soon'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: EdgeInsets.zero,
              backgroundColor: JT.surfaceAlt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, VoidCallback onTap, {double height = 44}) => SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: JT.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: jtBody(14, weight: FontWeight.w600, color: Colors.white)),
        ),
      );

  // ---------- highlights ----------

  Widget _highlightsRow() {
    final items = <Widget>[];
    if (widget.isOwner) {
      items.add(_HighlightCircle(
        label: 'New',
        onTap: widget.onNewHighlight,
        ring: JT.textFaint,
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ));
    }
    if (widget.onOpenMerch != null) {
      items.add(_HighlightCircle(
        label: 'Merch',
        onTap: widget.onOpenMerch,
        child: const Icon(Icons.checkroom_rounded, size: 28, color: JT.textMuted),
      ));
    }
    for (final hl in widget.highlights) {
      items.add(_HighlightCircle(
        label: hl.title,
        onTap: () => widget.onOpenHighlight?.call(hl),
        child: hl.coverUrl != null
            ? SizedBox.expand(child: Image.network(hl.coverUrl!, fit: BoxFit.cover))
            : const Icon(Icons.star_rounded, size: 28, color: JT.yellow),
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 114,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  Widget _tabIcon(int i, IconData icon) {
    final on = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: SizedBox(
          height: 48,
          child: Column(
            children: [
              Expanded(child: Center(child: Icon(icon, size: 22, color: on ? Colors.white : JT.textFaint))),
              Container(height: 2, width: 28, color: on ? Colors.white : Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightCircle extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final Color ring;
  const _HighlightCircle({required this.label, required this.child, this.onTap, this.ring = JT.border});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 1.5)),
              child: ClipOval(
                child: Container(color: JT.surfaceAlt, child: Center(child: child)),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: jtBody(12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}