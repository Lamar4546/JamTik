import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

enum _HandleStatus { unchanged, invalid, checking, available, taken, error }

/// Pops with the saved [UserProfile] on success.
class EditProfileScreen extends StatefulWidget {
  final UserProfile? current;
  const EditProfileScreen({super.key, this.current});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.current?.name ?? '');
  late final _handle = TextEditingController(text: widget.current?.handle ?? '');
  late final _bio = TextEditingController(text: widget.current?.bio ?? '');
  late final _website = TextEditingController(text: widget.current?.website ?? '');

  late final String _original = (widget.current?.handle ?? '').toLowerCase();
  late _HandleStatus _status = _original.isEmpty ? _HandleStatus.invalid : _HandleStatus.unchanged;
  String? _handleMessage;

  Uint8List? _avatar;
  Uint8List? _banner;
  Timer? _debounce;
  int _checkId = 0;
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    _website.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      (_status == _HandleStatus.available || _status == _HandleStatus.unchanged);

  // ---------- handle checking ----------

  String? _formatError(String h) {
    if (h.length < 3) return 'Use at least 3 characters';
    if (h.length > 30) return 'Use 30 characters or fewer';
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(h)) return 'Only letters, numbers, periods and underscores';
    if (h.startsWith('.') || h.endsWith('.')) return "Can't start or end with a period";
    if (h.contains('..')) return "Can't have two periods in a row";
    return null;
  }

  void _onHandleChanged(String value) {
    _debounce?.cancel();
    final h = value.trim().toLowerCase();
    final id = ++_checkId;

    if (h == _original && _original.isNotEmpty) {
      setState(() {
        _status = _HandleStatus.unchanged;
        _handleMessage = null;
      });
      return;
    }
    final problem = h.isEmpty ? 'Pick a handle' : _formatError(h);
    if (problem != null) {
      setState(() {
        _status = _HandleStatus.invalid;
        _handleMessage = h.isEmpty ? null : problem;
      });
      return;
    }

    setState(() {
      _status = _HandleStatus.checking;
      _handleMessage = null;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final ok = await Api.isHandleAvailable(h);
        if (!mounted || id != _checkId) return; // user kept typing
        setState(() {
          _status = ok ? _HandleStatus.available : _HandleStatus.taken;
          _handleMessage = ok ? '@$h is available' : '@$h is already taken';
        });
      } on BackendNotConnected catch (e) {
        if (!mounted || id != _checkId) return;
        setState(() {
          _status = _HandleStatus.error;
          _handleMessage = e.message;
        });
      }
    });
  }

  // ---------- images ----------

  Future<void> _pickImage({required bool banner}) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: banner ? 1600 : 800,
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => banner ? _banner = bytes : _avatar = bytes);
  }

  // ---------- save ----------

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await Api.updateProfile(
        name: _name.text.trim(),
        handle: _handle.text.trim().toLowerCase(),
        bio: _bio.text.trim(),
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
        avatar: _avatar,
        banner: _banner,
      );
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on BackendNotConnected catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(context, e.message);
      // The handle may have been taken between the check and the save.
      if (_handle.text.trim().toLowerCase() != _original) _onHandleChanged(_handle.text);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: JT.green),
                  )
                : Text('Save',
                    style: jtBody(15, weight: FontWeight.w700, color: _canSave ? JT.green : JT.textFaint)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _imagesHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Name'),
                TextField(
                  controller: _name,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  style: jtBody(15, color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Your name', counterText: ''),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Handle'),
                TextField(
                  controller: _handle,
                  maxLength: 30,
                  autocorrect: false,
                  onChanged: _onHandleChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._]')),
                    TextInputFormatter.withFunction(
                      (old, next) => next.copyWith(text: next.text.toLowerCase()),
                    ),
                  ],
                  style: jtBody(15, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'yourhandle',
                    counterText: '',
                    prefixText: '@',
                    prefixStyle: jtBody(15, color: JT.textMuted),
                    suffixIcon: _handleIcon(),
                  ),
                ),
                if (_handleMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_handleMessage!, style: jtBody(12, color: _handleColor())),
                  ),
                const SizedBox(height: 20),
                const FieldLabel('Bio'),
                TextField(
                  controller: _bio,
                  maxLength: 150,
                  maxLines: 4,
                  minLines: 3,
                  style: jtBody(15, color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Tell people about you or your events'),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Website'),
                TextField(
                  controller: _website,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: jtBody(15, color: Colors.white),
                  decoration: const InputDecoration(hintText: 'https://...'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _handleIcon() {
    switch (_status) {
      case _HandleStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: JT.textMuted)),
        );
      case _HandleStatus.available:
        return const Icon(Icons.check_circle_rounded, color: JT.green);
      case _HandleStatus.taken:
      case _HandleStatus.error:
        return const Icon(Icons.error_rounded, color: JT.danger);
      case _HandleStatus.invalid:
        return _handleMessage == null ? null : const Icon(Icons.error_rounded, color: JT.danger);
      case _HandleStatus.unchanged:
        return null;
    }
  }

  Color _handleColor() => _status == _HandleStatus.available ? JT.green : JT.danger;

  Widget _imagesHeader() {
    const bannerHeight = 150.0;
    const avatarSize = 92.0;
    final url = widget.current?.bannerUrl;
    final avatarUrl = widget.current?.avatarUrl;

    Widget bannerImage() {
      if (_banner != null) return Image.memory(_banner!, fit: BoxFit.cover);
      if (url != null) {
        return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bannerFallback());
      }
      return _bannerFallback();
    }

    return SizedBox(
      height: bannerHeight + avatarSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: GestureDetector(
              onTap: () => _pickImage(banner: true),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  bannerImage(),
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_camera_outlined, color: Colors.white),
                        const SizedBox(height: 4),
                        Text('Change banner', style: jtBody(12, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickImage(banner: false),
              child: Stack(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: JT.surfaceAlt,
                      border: Border.all(color: JT.bg, width: 4),
                      image: _avatar != null
                          ? DecorationImage(image: MemoryImage(_avatar!), fit: BoxFit.cover)
                          : (avatarUrl != null
                              ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                              : null),
                    ),
                    child: (_avatar == null && avatarUrl == null)
                        ? const Icon(Icons.person_rounded, size: 40, color: JT.textMuted)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: JT.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: JT.bg, width: 3),
                      ),
                      child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E2B), Color(0xFF0B0B0B), Color(0xFF3F3A06)],
          ),
        ),
      );
}