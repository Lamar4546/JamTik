import 'package:flutter/material.dart';

import '../models/settings_models.dart';
import '../widgets/settings_widgets.dart';

// ---------------- Notifications ----------------

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Notifications',
      builder: (c, s) {
        ValueChanged<bool>? on(AppSettings Function(AppSettings, bool) apply) =>
            s.pauseAll ? null : (v) => changeSetting(c, (x) => apply(x, v));

        return [
          SettingsSwitchTile(
            title: 'Pause all',
            subtitle: 'Temporarily stop push notifications.',
            value: s.pauseAll,
            onChanged: (v) => changeSetting(c, (x) => x.copyWith(pauseAll: v)),
          ),
          const SettingsHeader('Activity'),
          SettingsSwitchTile(
              title: 'Likes', value: s.notifyLikes, onChanged: on((x, v) => x.copyWith(notifyLikes: v))),
          SettingsSwitchTile(
              title: 'Comments', value: s.notifyComments, onChanged: on((x, v) => x.copyWith(notifyComments: v))),
          SettingsSwitchTile(
              title: 'New followers',
              value: s.notifyFollowers,
              onChanged: on((x, v) => x.copyWith(notifyFollowers: v))),
          const SettingsHeader('Events and tickets'),
          SettingsSwitchTile(
            title: 'Event reminders',
            subtitle: 'Before events you have tickets for.',
            value: s.notifyReminders,
            onChanged: on((x, v) => x.copyWith(notifyReminders: v)),
          ),
          SettingsSwitchTile(
            title: 'Ticket activity',
            subtitle: 'Transfers, trades and resales.',
            value: s.notifyTickets,
            onChanged: on((x, v) => x.copyWith(notifyTickets: v)),
          ),
          SettingsSwitchTile(
            title: 'Host announcements',
            subtitle: 'New events and updates from hosts you follow.',
            value: s.notifyAnnouncements,
            onChanged: on((x, v) => x.copyWith(notifyAnnouncements: v)),
          ),
          const SettingsHeader('Messages'),
          SettingsSwitchTile(
              title: 'Direct messages',
              value: s.notifyMessages,
              onChanged: on((x, v) => x.copyWith(notifyMessages: v))),
          const SettingsHeader('Email'),
          SettingsSwitchTile(
            title: 'Email notifications',
            subtitle: 'Receipts and ticket confirmations are always sent.',
            value: s.notifyEmail,
            onChanged: (v) => changeSetting(c, (x) => x.copyWith(notifyEmail: v)),
          ),
        ];
      },
    );
  }
}

// ---------------- Account privacy ----------------

class AccountPrivacyScreen extends StatelessWidget {
  const AccountPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Account privacy',
      builder: (c, s) => [
        const SizedBox(height: 8),
        SettingsSwitchTile(
          title: 'Private account',
          value: s.privateAccount,
          onChanged: (v) => changeSetting(c, (x) => x.copyWith(privateAccount: v)),
        ),
        const SettingsNote(
          'When your account is public, anyone can see your profile and events. '
          'When it is private, only followers you approve can see your events and activity. '
          'Your current followers are not affected.',
        ),
      ],
    );
  }
}

// ---------------- Messages and story replies ----------------

class MessagesSettingsScreen extends StatelessWidget {
  const MessagesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Messages and story replies',
      builder: (c, s) => [
        OptionGroup<Who>(
          title: 'Who can message you',
          options: const [Who.everyone, Who.following, Who.nobody],
          selected: s.messagesFrom,
          label: (w) => w.label,
          onSelected: (w) => changeSetting(c, (x) => x.copyWith(messagesFrom: w)),
          footer: 'People you have blocked can never message you.',
        ),
        OptionGroup<Who>(
          title: 'Who can reply to your stories',
          options: const [Who.everyone, Who.followers, Who.nobody],
          selected: s.storyRepliesFrom,
          label: (w) => w == Who.nobody ? 'Off' : w.label,
          onSelected: (w) => changeSetting(c, (x) => x.copyWith(storyRepliesFrom: w)),
        ),
      ],
    );
  }
}

// ---------------- Tags and mentions ----------------

class TagsMentionsScreen extends StatelessWidget {
  const TagsMentionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Tags and mentions',
      builder: (c, s) => [
        OptionGroup<Who>(
          title: 'Allow tags from',
          options: const [Who.everyone, Who.following, Who.nobody],
          selected: s.tagsFrom,
          label: (w) => w.label,
          onSelected: (w) => changeSetting(c, (x) => x.copyWith(tagsFrom: w)),
        ),
        OptionGroup<Who>(
          title: 'Allow mentions from',
          options: const [Who.everyone, Who.following, Who.nobody],
          selected: s.mentionsFrom,
          label: (w) => w.label,
          onSelected: (w) => changeSetting(c, (x) => x.copyWith(mentionsFrom: w)),
        ),
        const SizedBox(height: 12),
        SettingsSwitchTile(
          title: 'Manually approve tags',
          subtitle: 'Choose which tags appear on your profile.',
          value: s.approveTags,
          onChanged: (v) => changeSetting(c, (x) => x.copyWith(approveTags: v)),
        ),
      ],
    );
  }
}

// ---------------- Comments ----------------

class CommentsSettingsScreen extends StatelessWidget {
  const CommentsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Comments',
      builder: (c, s) => [
        OptionGroup<Who>(
          title: 'Allow comments from',
          options: const [Who.everyone, Who.followers, Who.following, Who.nobody],
          selected: s.commentsFrom,
          label: (w) => w.label,
          onSelected: (w) => changeSetting(c, (x) => x.copyWith(commentsFrom: w)),
        ),
        const SizedBox(height: 12),
        SettingsSwitchTile(
          title: 'Hide offensive comments',
          subtitle: 'Comments that may be offensive are hidden from your events.',
          value: s.hideOffensive,
          onChanged: (v) => changeSetting(c, (x) => x.copyWith(hideOffensive: v)),
        ),
      ],
    );
  }
}

// ---------------- Sharing and reshares ----------------

class SharingSettingsScreen extends StatelessWidget {
  const SharingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Sharing and reshares',
      builder: (c, s) => [
        const SizedBox(height: 8),
        SettingsSwitchTile(
          title: 'Allow reshares',
          subtitle: 'Let others reshare your events to their stories and profiles.',
          value: s.allowReshares,
          onChanged: (v) => changeSetting(c, (x) => x.copyWith(allowReshares: v)),
        ),
        SettingsSwitchTile(
          title: 'Allow sharing to messages',
          subtitle: 'Let others send your events to friends in direct messages.',
          value: s.allowShareToMessages,
          onChanged: (v) => changeSetting(c, (x) => x.copyWith(allowShareToMessages: v)),
        ),
      ],
    );
  }
}