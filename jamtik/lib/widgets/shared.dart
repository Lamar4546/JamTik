import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

Future<T?> pushPage<T>(BuildContext context, Widget page,
        {bool fullscreen = false}) =>
    Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page, fullscreenDialog: fullscreen),
    );

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message, style: jtBody(14, color: Colors.white))));
}

Future<T?> showJTSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: JT.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

/// "jamTik" wordmark: jam in green, Tik in yellow.
class JamTikWordmark extends StatelessWidget {
  final double size;
  final bool showIcon;
  const JamTikWordmark({super.key, this.size = 18, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            width: size + 6,
            height: size + 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            // TODO: swap for the real logo asset (Image.asset).
            child: Icon(Icons.confirmation_number_rounded,
                size: size * 0.85, color: JT.yellow),
          ),
          const SizedBox(width: 8),
        ],
        Text.rich(TextSpan(children: [
          TextSpan(text: 'jam', style: jtHeading(size, weight: FontWeight.w800, color: JT.green)),
          TextSpan(text: 'Tik', style: jtHeading(size, weight: FontWeight.w800, color: JT.yellow)),
        ])),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool glow;
  final IconData? trailingIcon;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glow = false,
    this.trailingIcon,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: glow && enabled
            ? [BoxShadow(color: JT.green.withValues(alpha: 0.35), blurRadius: 22)]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: JT.green,
            foregroundColor: Colors.black,
            disabledBackgroundColor: JT.surfaceAlt,
            disabledForegroundColor: JT.textFaint,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: jtBody(15, weight: FontWeight.w700, color: enabled ? Colors.black : JT.textFaint)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedCheck extends StatelessWidget {
  final double size;
  const VerifiedCheck({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: JT.green, shape: BoxShape.circle),
        child: Icon(Icons.check, size: size * 0.7, color: Colors.black),
      );
}

class TagChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  const TagChip(this.text, {super.key, this.color = JT.green, this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: jtBody(10, weight: FontWeight.w600, color: filled ? Colors.black : color)),
      );
}

class HostAvatar extends StatelessWidget {
  final Host host;
  final double size;
  const HostAvatar(this.host, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: JT.surfaceAlt,
        image: host.avatarUrl == null
            ? null
            : DecorationImage(image: NetworkImage(host.avatarUrl!), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: host.avatarUrl == null
          ? Text(host.initials, style: jtBody(size * 0.34, weight: FontWeight.w600, color: Colors.white))
          : null,
    );
  }
}

/// Story / highlight circle with a coloured ring.
class RingAvatar extends StatelessWidget {
  final String label;
  final Color ring;
  final Widget child;
  final double size;
  final VoidCallback? onTap;
  const RingAvatar({
    super.key,
    required this.label,
    required this.child,
    this.ring = JT.green,
    this.size = 56,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 2)),
            child: ClipOval(child: Container(color: JT.surfaceAlt, alignment: Alignment.center, child: child)),
          ),
          const SizedBox(height: 6),
          Text(label, style: jtBody(10)),
        ],
      ),
    );
  }
}

/// Flyer with graceful fallback when no image is available.
class FlyerImage extends StatelessWidget {
  final String? url;
  final String title;
  final double aspectRatio;
  const FlyerImage({super.key, required this.url, required this.title, this.aspectRatio = 1});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: url == null ? _fallback() : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
    );
  }

  Widget _fallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E2B), Color(0xFF0B0B0B), Color(0xFF3F3A06)],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(title.toUpperCase(),
            textAlign: TextAlign.center,
            style: jtHeading(28, weight: FontWeight.w800, color: JT.yellow)),
      );
}

/// Lavender image placeholder used in grids and merch rows.
class PlaceholderTile extends StatelessWidget {
  final double? size;
  final double radius;
  final String? imageUrl;
  const PlaceholderTile({super.key, this.size, this.radius = 14, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDDD6FE), Color(0xFFEDE9FE)],
                  ),
                ),
                child: const Center(child: Icon(Icons.landscape_rounded, size: 34, color: Color(0xFF3B1FFF))),
              ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(), style: jtBody(11, weight: FontWeight.w600).copyWith(letterSpacing: 0.8)),
      );
}

/// Segmented progress bar used by checkout / create-event / etc.
class StepBar extends StatelessWidget {
  final int total;
  final int current; // zero-based
  const StepBar({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= current ? JT.green : JT.surfaceAlt,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, this.color = const Color(0xFFD1D5DB)});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final count = (c.maxWidth / 10).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          count,
          (_) => Container(width: 5, height: 1.5, color: color),
        ),
      );
    });
  }
}

/// Bottom nav with the raised yellow "+" in the centre.
class JTBottomNav extends StatelessWidget {
  final int index; // 0 home, 1 explore, 2 tickets, 3 profile
  final ValueChanged<int> onTap;
  final VoidCallback onCreate;
  const JTBottomNav({super.key, required this.index, required this.onTap, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label) {
      final active = index == i;
      final color = active ? JT.green : JT.textFaint;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                i == 3
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: JT.surfaceAlt,
                          border: Border.all(color: active ? JT.green : Colors.transparent, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 14, color: Colors.white70),
                      )
                    : Icon(icon, size: 24, color: color),
                const SizedBox(height: 3),
                Text(label, style: jtBody(10, color: color, weight: active ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: JT.bg,
        border: Border(top: BorderSide(color: JT.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              item(0, Icons.home_rounded, 'Home'),
              item(1, Icons.search_rounded, 'Explore'),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: GestureDetector(
                      onTap: onCreate,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: JT.yellow,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: JT.yellow.withValues(alpha: 0.3), blurRadius: 14)],
                        ),
                        child: const Icon(Icons.add, color: Colors.black, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
              item(2, Icons.confirmation_number_rounded, 'Tickets'),
              item(3, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  const EmptyState({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: JT.textFaint),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: jtHeading(16)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!, textAlign: TextAlign.center, style: jtBody(12)),
              ],
            ],
          ),
        ),
      );
}
