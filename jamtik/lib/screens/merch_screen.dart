import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';

class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key});

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  static const _filters = ['All Items', 'T-Shirts', 'Accessories', 'Caps'];
  String _filter = _filters.first;
  int _cart = 0; // TODO: real cart state (provider / riverpod / bloc)

  @override
  Widget build(BuildContext context) {
    final items = AppData.merch.where((m) => _filter == 'All Items' || m.category == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: const Text('Official Merch'),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => toast(context, 'Cart coming soon'),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (_cart > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: JT.green, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$_cart', style: jtBody(9, weight: FontWeight.w700, color: Colors.black)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: JT.border)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final on = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? JT.green : JT.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f, style: jtBody(12, weight: FontWeight.w600, color: on ? Colors.black : JT.textMuted)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(icon: Icons.storefront_outlined, title: 'No merch yet'),
            )
          else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (_, i) => _MerchCard(item: items[i], onAdd: () => setState(() => _cart++)),
          ),
        ],
      ),
    );
  }
}

class _MerchCard extends StatelessWidget {
  final MerchItem item;
  final VoidCallback onAdd;
  const _MerchCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JT.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JT.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: PlaceholderTile(radius: 6, imageUrl: item.imageUrl)),
                  if (item.onSale)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: JT.yellow, borderRadius: BorderRadius.circular(4)),
                        child: Text('SALE', style: jtBody(9, weight: FontWeight.w800, color: Colors.black)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.brand, style: jtBody(11, color: JT.textFaint)),
          Text(item.name, style: jtBody(13, weight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(jmd(item.price), style: jtHeading(14, color: JT.green)),
              if (item.onSale) ...[
                const SizedBox(width: 6),
                Text(jmd(item.originalPrice!),
                    style: jtBody(10, color: JT.textFaint).copyWith(decoration: TextDecoration.lineThrough)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
