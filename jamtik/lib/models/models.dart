const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
];

/// 15000 -> J$15,000
String jmd(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'J\$${buf.toString()}';
}

/// 1200 -> 1.2k, 45000 -> 45k
String compact(int n) {
  if (n < 1000) return '$n';
  final k = n / 1000;
  return '${k.toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
}

String _two(int n) => n.toString().padLeft(2, '0');

String timeLabel(DateTime d, {bool padded = true}) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${padded ? _two(h) : h}:${_two(d.minute)} $ap';
}

/// JUL 20 • 8:00 PM
String dateTimeShort(DateTime d) =>
    '${_months[d.month - 1]} ${d.day} • ${timeLabel(d, padded: false)}';

String monthAbbr(DateTime d) => _months[d.month - 1];

class Host {
  final String id;
  final String handle;
  final String name;
  final String city;
  final String bio;
  final String? website;
  final String? avatarUrl;
  final String? bannerUrl; 
  final bool verified;
  final String badgeLabel;
  final int events;
  final int followers;
  final int following;

  const Host({
    required this.id,
    required this.handle,
    required this.name,
    required this.city,
    this.bio = '',
    this.website,
    this.avatarUrl,
    this.bannerUrl, 
    this.verified = false,
    this.badgeLabel = '',
    this.events = 0,
    this.followers = 0,
    this.following = 0,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}

class TicketTier {
  final String id;
  final String name;
  final String description;
  final int price; // JMD, 0 = free
  final int? remaining; // null = not tracked
  final bool soldOut;

  const TicketTier({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.remaining,
    this.soldOut = false,
  });

  bool get available => !soldOut && (remaining == null || remaining! > 0);
}

class MerchItem {
  final String id;
  final String brand;
  final String name;
  final String category; // 'T-Shirts' | 'Accessories' | 'Caps'
  final int price;
  final int? originalPrice;
  final String? imageUrl;

  const MerchItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    this.imageUrl,
  });

  bool get onSale => originalPrice != null && originalPrice! > price;
}

class Event {
  final String id;
  final String title;
  final Host host;
  final String venue;
  final String city;
  final DateTime date;
  final String description;
  final String? flyerUrl;
  final List<TicketTier> tiers;
  final List<MerchItem> merch;
  final int likes;
  final int comments;
  final int? spotsLeft;
  final int maxPerPerson;

  const Event({
    required this.id,
    required this.title,
    required this.host,
    required this.venue,
    required this.city,
    required this.date,
    required this.description,
    required this.tiers,
    this.flyerUrl,
    this.merch = const [],
    this.likes = 0,
    this.comments = 0,
    this.spotsLeft,
    this.maxPerPerson = 4,
  });

  bool get isVerified => host.verified;
  bool get isFree => tiers.every((t) => t.price == 0);

  int get startingPrice {
    final open = tiers.where((t) => t.available).map((t) => t.price);
    return open.isEmpty ? 0 : open.reduce((a, b) => a < b ? a : b);
  }

  String get priceLabel => isFree ? 'Free' : '${jmd(startingPrice)} up';
}

class OwnedTicket {
  final String orderId;
  final Event event;
  final TicketTier tier;
  final String guest;

  const OwnedTicket({
    required this.orderId,
    required this.event,
    required this.tier,
    required this.guest,
  });

  bool get isFree => tier.price == 0;
}

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String? handle;
  final String? bio;
  final String? website;
  final String? avatarUrl;
  final String? bannerUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.handle,
    this.bio,
    this.website,
    this.avatarUrl,
    this.bannerUrl,
  });

  Host toHost() => Host(
        id: id,
        handle: handle ?? '',
        name: name,
        city: '',
        bio: bio ?? '',
        website: website,
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
      );
}

class VerificationApplication {
  final DateTime submittedAt;
  /// 0 = documents submitted, 1 = identity verification, 2 = badge awarded
  final int stage;
  const VerificationApplication({required this.submittedAt, required this.stage});
}

class Highlight {
  final String id;
  final String title;
  final String? coverUrl;
  const Highlight({required this.id, required this.title, this.coverUrl});
}