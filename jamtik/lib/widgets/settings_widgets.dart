import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/settings_store.dart';
import '../models/settings_models.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

/// Applies a settings change. Shows the error and reverts if saving fails.
Future<void> changeSetting(BuildContext context, AppSettings Function(AppSettings s) change) async {
  final store = SettingsStore.instance;
  try {
    await store.update(change(store.value));
  } catch (e) {
    if (context.mounted) {
      toast(context, e is BackendNotConnected ? e.message : 'Could not save. Check your connection.');
    }
  }
}

class SettingsHeader extends StatelessWidget {
  final String text;
  const SettingsHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 6),
        child: Text(text, style: jtBody(13, weight: FontWeight.w600, color: Colors.white70)),
      );
}

class SettingsNote extends StatelessWidget {
  final String text;
  const SettingsNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Text(text, style: jtBody(12).copyWith(height: 1.45)),
      );
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final Color? color; // set for destructive rows (no chevron)
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? Colors.white, size: 24),
        title: Text(title, style: jtBody(15, weight: FontWeight.w500, color: color ?? Colors.white)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: jtBody(12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) Text(trailingText!, style: jtBody(13, color: JT.textMuted)),
            if (color == null) const Icon(Icons.chevron_right_rounded, color: JT.textFaint),
          ],
        ),
      );
}

final _switchTheme = SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Colors.black : JT.textMuted),
  trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? JT.green : JT.surfaceAlt),
  trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
);

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged; // null = disabled
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(switchTheme: _switchTheme),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(title,
              style: jtBody(15, weight: FontWeight.w500, color: onChanged == null ? JT.textFaint : Colors.white)),
          subtitle: subtitle == null ? null : Text(subtitle!, style: jtBody(12)),
        ),
      );
}

/// A titled list of options where exactly one is selected.
class OptionGroup<T> extends StatelessWidget {
  final String title;
  final String? footer;
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  const OptionGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsHeader(title),
          for (final o in options)
            ListTile(
              onTap: () => onSelected(o),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(label(o), style: jtBody(15, color: Colors.white)),
              trailing: Icon(
                o == selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: o == selected ? JT.green : JT.textFaint,
              ),
            ),
          if (footer != null) SettingsNote(footer!),
        ],
      );
}

/// A settings page that rebuilds whenever SettingsStore changes.
class SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> Function(BuildContext context, AppSettings s) builder;
  const SettingsPage({super.key, required this.title, required this.builder});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListenableBuilder(
          listenable: SettingsStore.instance,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: builder(context, SettingsStore.instance.value),
          ),
        ),
      );
}