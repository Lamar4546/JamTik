import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../widgets/profile_view.dart';
import '../widgets/shared.dart';
import 'merch_screen.dart';

/// Another host's public profile.
class HostProfileScreen extends StatelessWidget {
  final Host host;
  const HostProfileScreen({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theirs = AppData.events.where((e) => e.host.id == host.id).toList();

    return Scaffold(
      body: ProfileView(
        host: host,
        isOwner: false,
        upcoming: theirs.where((e) => e.date.isAfter(now)).toList(),
        past: theirs.where((e) => !e.date.isAfter(now)).toList(),
        // TODO: load this host's highlights and pass them as `highlights`.
        onBack: () => Navigator.pop(context),
        onOpenMerch: () => pushPage<void>(context, const MerchScreen()),
      ),
    );
  }
}