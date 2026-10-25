import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/app_data.dart';
import '../models/settings_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

enum PeopleListKind { closeFriends, blocked }

class PeopleListScreen extends StatefulWidget {
  final PeopleListKind kind;
  const PeopleListScreen({super.key, required this.kind});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  bool get _isClose => widget.kind == PeopleListKind.closeFriends;
  List<PersonSummary> get _people => _isClose ? AppData.closeFriends : AppData.blocked;

  Future<void> _remove(PersonSummary p) async {
    try {
      if (_isClose) {
        await Api.setCloseFriend(p.id, false);
      } else {
        await Api.setBlocked(p.id, false);
      }
      if (!mounted) return;
      setState(() => _people.removeWhere((x) => x.id == p.id));
    } on BackendNotConnected catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  void _openSearch() {
    final ctrl = TextEditingController();
    Timer? debounce;
    var results = <PersonSummary>[];
    String? error;
    var loading = false;

    showJTSheet<void>(context, (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> run(String q) async {
          if (q.trim().length < 2) {
            setSheet(() {
              results = [];
              error = null;
            });
            return;
          }
          setSheet(() {
            loading = true;
            error = null;
          });
          try {
            final r = await Api.searchPeople(q.trim());
            setSheet(() {
              results = r;
              loading = false;
            });
          } on BackendNotConnected catch (e) {
            setSheet(() {
              loading = false;
              error = e.message;
            });
          }
        }

        final shown = results.where((p) => !_people.any((x) => x.id == p.id)).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to close friends', style: jtHeading(18)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: jtBody(15, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: JT.textFaint),
              ),
              onChanged: (v) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 400), () => run(v));
              },
            ),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: JT.green)),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(error!, style: jtBody(12, color: JT.danger)),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in shown)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Avatar(p),
                      title: Text(p.name, style: jtBody(14, weight: FontWeight.w600, color: Colors.white)),
                      subtitle: Text('@${p.handle}', style: jtBody(12)),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            await Api.setCloseFriend(p.id, true);
                            if (!mounted) return;
                            setState(() => AppData.closeFriends.add(p));
                            setSheet(() {});
                          } on BackendNotConnected catch (e) {
                            setSheet(() => error = e.message);
                          }
                        },
                        child: Text('Add', style: jtBody(13, weight: FontWeight.w700, color: JT.green)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      });
    }).whenComplete(() {
      debounce?.cancel();
      ctrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final people = _people;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isClose ? 'Close friends' : 'Blocked'),
        actions: [
          if (_isClose)
            IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: _openSearch),
        ],
      ),
      body: people.isEmpty
          ? EmptyState(
              icon: _isClose ? Icons.star_border_rounded : Icons.block_rounded,
              title: _isClose ? 'No close friends yet' : 'No blocked accounts',
              message: _isClose
                  ? "Add people to share events and stories with just them. jamTik won't tell them you added them."
                  : "When you block someone, they can't see your profile or message you. You can block someone from their profile.",
            )
          : ListView(
              children: [
                if (_isClose)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(
                      "jamTik doesn't tell people when you add or remove them.",
                      style: TextStyle(color: JT.textMuted, fontSize: 12),
                    ),
                  ),
                for (final p in people)
                  ListTile(
                    leading: _Avatar(p),
                    title: Text(p.name, style: jtBody(14, weight: FontWeight.w600, color: Colors.white)),
                    subtitle: Text('@${p.handle}', style: jtBody(12)),
                    trailing: OutlinedButton(
                      onPressed: () => _remove(p),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: JT.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_isClose ? 'Remove' : 'Unblock',
                          style: jtBody(12, weight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PersonSummary p;
  const _Avatar(this.p);

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 22,
        backgroundColor: JT.surfaceAlt,
        backgroundImage: p.avatarUrl == null ? null : NetworkImage(p.avatarUrl!),
        child: p.avatarUrl == null
            ? Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                style: jtBody(15, weight: FontWeight.w600, color: Colors.white))
            : null,
      );
}