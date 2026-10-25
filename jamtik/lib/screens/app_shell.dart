import 'package:flutter/material.dart';

import '../widgets/shared.dart';
import 'create_event_screen.dart';
import 'explore_screen.dart';
import 'home_feed_screen.dart';
import 'profile_screen.dart';
import 'tickets_screen.dart';
import '../data/settings_store.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeFeedScreen(),
    ExploreScreen(),
    TicketsScreen(),
    ProfileScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    SettingsStore.instance.load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: JTBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        onCreate: () => pushPage<void>(context, const CreateEventScreen(), fullscreen: true),
      ),
    );
  }
}
