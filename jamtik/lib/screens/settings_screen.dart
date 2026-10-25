import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../data/session.dart';
import '../data/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/shared.dart';
import 'event_grid_screen.dart';
import 'login_screen.dart';
import 'payment_methods_screen.dart';
import 'people_list_screen.dart';
import 'settings_pages.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Opens a page and refreshes the counts shown on this screen when it closes.
  void _open(Widget page) => pushPage<void>(context, page).then((_) {
        if (mounted) setState(() {});
      });

  Future<void> _logout() async {
    await Session.clear();
    AppData.user = null;
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings and activity')),
      body: ListenableBuilder(
        listenable: SettingsStore.instance,
        builder: (context, _) {
          final s = SettingsStore.instance.value;
          String? count(int n) => n == 0 ? null : '$n';

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const SettingsHeader('How you use jamTik'),
              SettingsTile(
                icon: Icons.bookmark_border_rounded,
                title: 'Saved',
                onTap: () => _open(EventGridScreen(
                  title: 'Saved',
                  events: AppData.savedEvents,
                  emptyTitle: 'Nothing saved yet',
                  emptyMessage: 'Tap the bookmark on an event to save it here.',
                )),
              ),
              SettingsTile(
                icon: Icons.history_rounded,
                title: 'Archive',
                onTap: () => _open(EventGridScreen(
                  title: 'Archive',
                  events: AppData.archivedEvents,
                  emptyTitle: 'Nothing archived',
                  emptyMessage: 'Events you archive are hidden from your profile and kept here. Only you can see them.',
                )),
              ),
              SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                trailingText: s.pauseAll ? 'Paused' : null,
                onTap: () => _open(const NotificationSettingsScreen()),
              ),
              const SettingsHeader('Who can see your content'),
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Account privacy',
                trailingText: s.privateAccount ? 'Private' : 'Public',
                onTap: () => _open(const AccountPrivacyScreen()),
              ),
              SettingsTile(
                icon: Icons.star_border_rounded,
                title: 'Close friends',
                trailingText: count(AppData.closeFriends.length),
                onTap: () => _open(const PeopleListScreen(kind: PeopleListKind.closeFriends)),
              ),
              SettingsTile(
                icon: Icons.block_rounded,
                title: 'Blocked',
                trailingText: count(AppData.blocked.length),
                onTap: () => _open(const PeopleListScreen(kind: PeopleListKind.blocked)),
              ),
              const SettingsHeader('How others can interact with you'),
              SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages and story replies',
                onTap: () => _open(const MessagesSettingsScreen()),
              ),
              SettingsTile(
                icon: Icons.alternate_email_rounded,
                title: 'Tags and mentions',
                onTap: () => _open(const TagsMentionsScreen()),
              ),
              SettingsTile(
                icon: Icons.mode_comment_outlined,
                title: 'Comments',
                onTap: () => _open(const CommentsSettingsScreen()),
              ),
              SettingsTile(
                icon: Icons.repeat_rounded,
                title: 'Sharing and reshares',
                onTap: () => _open(const SharingSettingsScreen()),
              ),
              const SettingsHeader('Payments'),
              SettingsTile(
                icon: Icons.credit_card_rounded,
                title: 'Payment methods',
                trailingText: count(AppData.cards.length),
                onTap: () => _open(const PaymentMethodsScreen()),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: JT.border),
              SettingsTile(icon: Icons.logout_rounded, title: 'Log out', color: JT.danger, onTap: _logout),
            ],
          );
        },
      ),
    );
  }
}