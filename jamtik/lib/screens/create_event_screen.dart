
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

class TierDraft {
  String name;
  int price;
  int quantity;
  TierDraft({required this.name, required this.price, required this.quantity});
}

/// Create Event, step 1 of 4 ("Event Basics").
/// TODO: steps 2-4 (details, ticket rules, review & publish).
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  final _venue = TextEditingController();
  Uint8List? _flyer;
  DateTime? _date;
  TimeOfDay? _time;
  final List<TierDraft> _tiers = [];

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickFlyer() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _flyer = bytes);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0));
    if (t != null) setState(() => _time = t);
  }

  String get _dateText => _date == null
      ? 'mm/dd/yyyy'
      : '${_date!.month.toString().padLeft(2, '0')}/${_date!.day.toString().padLeft(2, '0')}/${_date!.year}';

  String get _timeText => _time == null ? '--:-- --' : _time!.format(context);

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      _date != null &&
      _time != null &&
      _venue.text.trim().isNotEmpty &&
      _tiers.isNotEmpty;

  void _editTier({int? index}) {
    final existing = index == null ? null : _tiers[index];
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(text: existing?.price.toString() ?? '');
    final qty = TextEditingController(text: existing?.quantity.toString() ?? '');

    showJTSheet<void>(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(existing == null ? 'Add ticket tier' : 'Edit ticket tier', style: jtHeading(18)),
          const SizedBox(height: 16),
          const FieldLabel('Tier name'),
          TextField(controller: name, decoration: const InputDecoration(hintText: 'e.g. VIP')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Price (J\$, 0 = free)'),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '5000'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Tickets available'),
                    TextField(
                      controller: qty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: '500'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (existing != null) ...[
                IconButton(
                  onPressed: () {
                    setState(() => _tiers.removeAt(index!));
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: JT.danger),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: PrimaryButton(
                  label: 'Save tier',
                  onPressed: () {
                    final n = name.text.trim();
                    final p = int.tryParse(price.text);
                    final q = int.tryParse(qty.text);
                    if (n.isEmpty || p == null || q == null || q <= 0) return;
                    setState(() {
                      if (existing == null) {
                        _tiers.add(TierDraft(name: n, price: p, quantity: q));
                      } else {
                        existing
                          ..name = n
                          ..price = p
                          ..quantity = q;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Create Event'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await Api.saveDraft();
                if (mounted) toast(context, 'Draft saved');
              } on BackendNotConnected catch (e) {
                if (mounted) toast(context, e.message);
              }
            },
            child: Text('Draft', style: jtBody(13, weight: FontWeight.w600, color: JT.green)),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: StepBar(total: 4, current: 0),
          ),
          const Divider(height: 1, color: JT.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Event Basics', style: jtHeading(22)),
                const SizedBox(height: 20),
                const FieldLabel('Event title'),
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  style: jtBody(15, color: Colors.white),
                  decoration: const InputDecoration(hintText: 'e.g. Summer Jam 2027'),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Event flyer'),
                GestureDetector(
                  onTap: _pickFlyer,
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: JT.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: _flyer != null
                        ? Image.memory(_flyer!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_rounded, size: 34, color: JT.textFaint),
                              const SizedBox(height: 8),
                              Text('Tap to upload flyer (JPG, PNG)', style: jtBody(11, color: JT.textFaint)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Date'),
                          _pickerField(_dateText, Icons.calendar_today_rounded, _pickDate, _date != null),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Time'),
                          _pickerField(_timeText, Icons.access_time_rounded, _pickTime, _time != null),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const FieldLabel('Venue / location'),
                TextField(
                  controller: _venue,
                  onChanged: (_) => setState(() {}),
                  style: jtBody(15, color: Colors.white),
                  // TODO: hook up a places search (Google Places or similar).
                  decoration: const InputDecoration(
                    hintText: 'Search for a venue...',
                    prefixIcon: Icon(Icons.location_on_rounded, size: 18, color: JT.textFaint),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticketing', style: jtHeading(18)),
                    TextButton.icon(
                      onPressed: () => _editTier(),
                      icon: const Icon(Icons.add, size: 16, color: JT.green),
                      label: Text('Add Tier', style: jtBody(12, weight: FontWeight.w600, color: JT.green)),
                    ),
                  ],
                ),
                for (var i = 0; i < _tiers.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    decoration: BoxDecoration(
                      color: JT.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JT.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_tiers[i].name, style: jtBody(14, weight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                '${_tiers[i].price == 0 ? 'Free' : jmd(_tiers[i].price)} • ${_tiers[i].quantity} tickets',
                                style: jtBody(11, color: JT.textFaint),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: JT.surfaceAlt),
                          onPressed: () => _editTier(index: i),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: JT.border))),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: 'Next Step',
                glow: true,
                height: 52,
                onPressed: _valid ? () => toast(context, 'Step 2 coming next') : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerField(String text, IconData icon, VoidCallback onTap, bool filled) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: JT.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: JT.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: jtBody(14, color: filled ? Colors.white : JT.textMuted)),
              ),
              Icon(icon, size: 16, color: JT.textMuted),
            ],
          ),
        ),
      );
}
