import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';
import '../data/api.dart';
import '../data/app_data.dart';
import '../data/session.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_view.dart';
import '../widgets/shared.dart';
import 'host_verification_screen.dart';
import 'login_screen.dart';
import 'merch_screen.dart';
import 'settings_screen.dart';

/// The signed-in user's own profile tab.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: load from your backend after sign-in.
  final List<Highlight> _highlights = [];

  Host get _host =>
      AppData.user?.toHost() ?? const Host(id: 'me', handle: '', name: 'Your account', city: '');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mine = AppData.myEvents;

    return Scaffold(
      body: ProfileView(
        host: _host,
        isOwner: true,
        highlights: _highlights,
        upcoming: mine.where((e) => e.date.isAfter(now)).toList(),
        past: mine.where((e) => !e.date.isAfter(now)).toList(),
        onMenu: _openMenu,
        onNewHighlight: _newHighlight,
        onOpenHighlight: (_) => toast(context, 'Highlight viewer coming soon'),
                onEditProfile: () async {
          final updated = await pushPage<UserProfile>(context, EditProfileScreen(current: AppData.user));
          if (updated != null && mounted) setState(() => AppData.user = updated);
        },
      ),
    );
  }

  void _openMenu() {
    showJTSheet<void>(context, (ctx) {
      Widget row(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color == Colors.white ? JT.textMuted : color),
            title: Text(label, style: jtBody(15, weight: FontWeight.w500, color: color)),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(Icons.verified_rounded, 'Apply for host verification',
              () => pushPage<void>(context, const HostVerificationScreen())),
          row(Icons.storefront_rounded, 'Official merch', () => pushPage<void>(context, const MerchScreen())),
          row(Icons.event_note_rounded, 'My events', () => toast(context, 'Coming soon')),
                   row(Icons.settings_rounded, 'Settings', () => pushPage<void>(context, const SettingsScreen())),
          row(Icons.logout_rounded, 'Log out', _logout, color: JT.danger),
        ],
      );
    });
  }

  Future<void> _logout() async {
    await Session.clear();
    AppData.user = null;
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _newHighlight() {
    final title = TextEditingController();
    Uint8List? cover;
    String? error;

    showJTSheet<void>(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New highlight', style: jtHeading(18)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
                  if (f == null) return;
                  final bytes = await f.readAsBytes();
                  setSheet(() => cover = bytes);
                },
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: JT.surfaceAlt,
                    border: Border.all(color: JT.textFaint),
                    image: cover == null
                        ? null
                        : DecorationImage(image: MemoryImage(cover!), fit: BoxFit.cover),
                  ),
                  child: cover == null
                      ? const Icon(Icons.add_photo_alternate_outlined, color: JT.textMuted)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(child: Text('Cover', style: jtBody(11, color: JT.textFaint))),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              maxLength: 15,
              style: jtBody(15, color: Colors.white),
              decoration: InputDecoration(hintText: 'Highlight name', counterText: '', errorText: error),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Create',
              onPressed: () async {
                final t = title.text.trim();
                if (t.isEmpty) {
                  setSheet(() => error = 'Give it a name');
                  return;
                }
                try {
                  final created = await Api.createHighlight(title: t, cover: cover);
                  if (!mounted) return;
                  setState(() => _highlights.add(created));
                  Navigator.pop(ctx);
                } on BackendNotConnected catch (e) {
                  setSheet(() => error = e.message);
                }
              },
            ),
          ],
        );
      });
    });
  }
}