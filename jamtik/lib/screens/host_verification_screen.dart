import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

enum _StepState { done, active, pending }

class HostVerificationScreen extends StatefulWidget {
  const HostVerificationScreen({super.key});

  @override
  State<HostVerificationScreen> createState() => _HostVerificationScreenState();
}

class _HostVerificationScreenState extends State<HostVerificationScreen> {
  static const _accountTypes = ['Event Promoter', 'Artist', 'Official Organization'];

  String _accountType = _accountTypes.first;
  final _website = TextEditingController();
  String? _proofName;

  VerificationApplication? get _application => AppData.verification;

  @override
  void dispose() {
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res != null && res.files.isNotEmpty && mounted) {
      setState(() => _proofName = res.files.single.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: const Text('Host Verification'),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: JT.border)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_application != null) ...[
            _statusCard(_application!),
            const SizedBox(height: 32),
          ],
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: JT.green.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: const Center(child: VerifiedCheck(size: 32)),
            ),
          ),
          const SizedBox(height: 14),
          Center(child: Text('Apply for Verification', style: jtHeading(24, weight: FontWeight.w800))),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Verified badges are reserved for established\npromoters, artists, and official organizations.',
              textAlign: TextAlign.center,
              style: jtBody(12).copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          const FieldLabel('Account type'),
          DropdownButtonFormField<String>(
            initialValue: _accountType,
            dropdownColor: JT.surfaceAlt,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JT.textMuted),
            style: jtBody(15, color: Colors.white),
            items: [for (final t in _accountTypes) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _accountType = v ?? _accountType),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Official website / portfolio'),
          TextField(
            controller: _website,
            keyboardType: TextInputType.url,
            style: jtBody(15, color: Colors.white),
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Proof of identity (ID/business license)'),
          GestureDetector(
            onTap: _pickProof,
            child: Container(
              height: 104,
              decoration: BoxDecoration(color: JT.surfaceAlt, borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_proofName == null ? Icons.upload_file_rounded : Icons.description_rounded,
                      size: 30, color: _proofName == null ? JT.textFaint : JT.green),
                  const SizedBox(height: 8),
                  Text(_proofName ?? 'Upload PDF or JPG',
                      style: jtBody(12, color: _proofName == null ? JT.textFaint : Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: JT.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JT.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_rounded, size: 16, color: JT.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verification takes 3-5 business days. We may contact you for further documentation if required.',
                    style: jtBody(11).copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Not in the mock-up, but the form needs a submit action.
          PrimaryButton(
            label: 'Submit application',
            glow: true,
            onPressed: _proofName == null
                ? null
                : () async {
                    try {
                      await Api.submitVerification(
                        accountType: _accountType,
                        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
                        proofFileName: _proofName!,
                      );
                      if (mounted) toast(context, 'Application submitted');
                    } on BackendNotConnected catch (e) {
                      if (mounted) toast(context, e.message);
                    }
                  },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statusCard(VerificationApplication app) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: JT.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: JT.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Application Status', style: jtHeading(17)),
                TagChip(app.stage >= 2 ? 'VERIFIED' : 'IN REVIEW', color: app.stage >= 2 ? JT.green : JT.yellow),
              ],
            ),
            const SizedBox(height: 18),
            _StatusStep(
              title: 'Documents Submitted',
              subtitle: '${monthAbbr(app.submittedAt)} ${app.submittedAt.day}, ${app.submittedAt.year}',
              state: _StepState.done,
            ),
            _StatusStep(
              title: 'Identity Verification',
              subtitle: app.stage >= 2 ? 'Complete' : 'Processing...',
              state: app.stage >= 2 ? _StepState.done : _StepState.active,
            ),
            _StatusStep(
              title: 'Verification Badge Awarded',
              subtitle: app.stage >= 2 ? 'Awarded' : 'Pending',
              state: app.stage >= 2 ? _StepState.done : _StepState.pending,
              last: true,
            ),
          ],
        ),
      );
}

class _StatusStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final _StepState state;
  final bool last;
  const _StatusStep({required this.title, required this.subtitle, required this.state, this.last = false});

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final active = state == _StepState.active;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? JT.green : (active ? Colors.transparent : JT.surfaceAlt),
                    border: active ? Border.all(color: JT.green, width: 2) : null,
                  ),
                  child: done ? const Icon(Icons.check, size: 11, color: Colors.black) : null,
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: done ? JT.green : JT.surfaceAlt)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: jtBody(13,
                          weight: FontWeight.w600,
                          color: done ? Colors.white : (active ? JT.green : JT.textFaint))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: jtBody(11, color: JT.textFaint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
