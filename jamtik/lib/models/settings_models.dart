enum Who { everyone, followers, following, nobody }

extension WhoLabel on Who {
  String get label {
    switch (this) {
      case Who.everyone:
        return 'Everyone';
      case Who.followers:
        return 'Your followers';
      case Who.following:
        return 'People you follow';
      case Who.nobody:
        return 'No one';
    }
  }
}

class AppSettings {
  final bool privateAccount;

  // Notifications
  final bool pauseAll;
  final bool notifyLikes;
  final bool notifyComments;
  final bool notifyFollowers;
  final bool notifyReminders;
  final bool notifyTickets;
  final bool notifyAnnouncements;
  final bool notifyMessages;
  final bool notifyEmail;

  // Interactions
  final Who messagesFrom;
  final Who storyRepliesFrom;
  final Who tagsFrom;
  final Who mentionsFrom;
  final bool approveTags;
  final Who commentsFrom;
  final bool hideOffensive;
  final bool allowReshares;
  final bool allowShareToMessages;

  const AppSettings({
    this.privateAccount = false,
    this.pauseAll = false,
    this.notifyLikes = true,
    this.notifyComments = true,
    this.notifyFollowers = true,
    this.notifyReminders = true,
    this.notifyTickets = true,
    this.notifyAnnouncements = true,
    this.notifyMessages = true,
    this.notifyEmail = true,
    this.messagesFrom = Who.everyone,
    this.storyRepliesFrom = Who.everyone,
    this.tagsFrom = Who.everyone,
    this.mentionsFrom = Who.everyone,
    this.approveTags = false,
    this.commentsFrom = Who.everyone,
    this.hideOffensive = true,
    this.allowReshares = true,
    this.allowShareToMessages = true,
  });

  AppSettings copyWith({
    bool? privateAccount,
    bool? pauseAll,
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyFollowers,
    bool? notifyReminders,
    bool? notifyTickets,
    bool? notifyAnnouncements,
    bool? notifyMessages,
    bool? notifyEmail,
    Who? messagesFrom,
    Who? storyRepliesFrom,
    Who? tagsFrom,
    Who? mentionsFrom,
    bool? approveTags,
    Who? commentsFrom,
    bool? hideOffensive,
    bool? allowReshares,
    bool? allowShareToMessages,
  }) =>
      AppSettings(
        privateAccount: privateAccount ?? this.privateAccount,
        pauseAll: pauseAll ?? this.pauseAll,
        notifyLikes: notifyLikes ?? this.notifyLikes,
        notifyComments: notifyComments ?? this.notifyComments,
        notifyFollowers: notifyFollowers ?? this.notifyFollowers,
        notifyReminders: notifyReminders ?? this.notifyReminders,
        notifyTickets: notifyTickets ?? this.notifyTickets,
        notifyAnnouncements: notifyAnnouncements ?? this.notifyAnnouncements,
        notifyMessages: notifyMessages ?? this.notifyMessages,
        notifyEmail: notifyEmail ?? this.notifyEmail,
        messagesFrom: messagesFrom ?? this.messagesFrom,
        storyRepliesFrom: storyRepliesFrom ?? this.storyRepliesFrom,
        tagsFrom: tagsFrom ?? this.tagsFrom,
        mentionsFrom: mentionsFrom ?? this.mentionsFrom,
        approveTags: approveTags ?? this.approveTags,
        commentsFrom: commentsFrom ?? this.commentsFrom,
        hideOffensive: hideOffensive ?? this.hideOffensive,
        allowReshares: allowReshares ?? this.allowReshares,
        allowShareToMessages: allowShareToMessages ?? this.allowShareToMessages,
      );

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    bool b(String key, bool fallback) => j[key] is bool ? j[key] as bool : fallback;
    Who w(String key, Who fallback) =>
        Who.values.firstWhere((x) => x.name == j[key], orElse: () => fallback);
    return AppSettings(
      privateAccount: b('private_account', d.privateAccount),
      pauseAll: b('pause_all', d.pauseAll),
      notifyLikes: b('notify_likes', d.notifyLikes),
      notifyComments: b('notify_comments', d.notifyComments),
      notifyFollowers: b('notify_followers', d.notifyFollowers),
      notifyReminders: b('notify_reminders', d.notifyReminders),
      notifyTickets: b('notify_tickets', d.notifyTickets),
      notifyAnnouncements: b('notify_announcements', d.notifyAnnouncements),
      notifyMessages: b('notify_messages', d.notifyMessages),
      notifyEmail: b('notify_email', d.notifyEmail),
      messagesFrom: w('messages_from', d.messagesFrom),
      storyRepliesFrom: w('story_replies_from', d.storyRepliesFrom),
      tagsFrom: w('tags_from', d.tagsFrom),
      mentionsFrom: w('mentions_from', d.mentionsFrom),
      approveTags: b('approve_tags', d.approveTags),
      commentsFrom: w('comments_from', d.commentsFrom),
      hideOffensive: b('hide_offensive', d.hideOffensive),
      allowReshares: b('allow_reshares', d.allowReshares),
      allowShareToMessages: b('allow_share_to_messages', d.allowShareToMessages),
    );
  }

  Map<String, dynamic> toJson() => {
        'private_account': privateAccount,
        'pause_all': pauseAll,
        'notify_likes': notifyLikes,
        'notify_comments': notifyComments,
        'notify_followers': notifyFollowers,
        'notify_reminders': notifyReminders,
        'notify_tickets': notifyTickets,
        'notify_announcements': notifyAnnouncements,
        'notify_messages': notifyMessages,
        'notify_email': notifyEmail,
        'messages_from': messagesFrom.name,
        'story_replies_from': storyRepliesFrom.name,
        'tags_from': tagsFrom.name,
        'mentions_from': mentionsFrom.name,
        'approve_tags': approveTags,
        'comments_from': commentsFrom.name,
        'hide_offensive': hideOffensive,
        'allow_reshares': allowReshares,
        'allow_share_to_messages': allowShareToMessages,
      };
}

/// A person in a list (close friends, blocked, search results).
class PersonSummary {
  final String id;
  final String handle;
  final String name;
  final String? avatarUrl;
  const PersonSummary({required this.id, required this.handle, required this.name, this.avatarUrl});
}

/// A saved card. Only safe display info; never the full number or CVC.
class PaymentCard {
  final String id;
  final String brand; // Visa, Mastercard, ...
  final String last4;
  final int expMonth;
  final int expYear; // four digits
  final bool isDefault;
  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  String get label => '$brand •••• $last4';
  String get expiry => '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  PaymentCard copyWith({bool? isDefault}) => PaymentCard(
        id: id,
        brand: brand,
        last4: last4,
        expMonth: expMonth,
        expYear: expYear,
        isDefault: isDefault ?? this.isDefault,
      );
}

/// Raw card details typed by the user. Hand to the payment provider, never log or store.
class CardInput {
  final String holderName;
  final String number; // digits only
  final int expMonth;
  final int expYear; // four digits
  final String cvc;
  final bool makeDefault;
  const CardInput({
    required this.holderName,
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvc,
    this.makeDefault = false,
  });

  @override
  String toString() => 'CardInput(****)'; // keeps card data out of logs
}