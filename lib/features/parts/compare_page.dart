import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import 'parts_provider.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Map<String, dynamic>? _left;
  Map<String, dynamic>? _right;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandingkan Komponen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdown(provider.parts, _left, (value) => setState(() => _left = value))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown(provider.parts, _right, (value) => setState(() => _right = value))),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCard(_left)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCard(_right)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<Map<String, dynamic>> items,
    Map<String, dynamic>? selected,
    ValueChanged<Map<String, dynamic>?> onChanged,
  ) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: selected,
      decoration: const InputDecoration(labelText: 'Pilih komponen'),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item['name']?.toString() ?? '-'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCard(Map<String, dynamic>? item) {
    if (item == null) {
      return const Center(child: Text('Belum dipilih'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Brand: ${item['brand'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Harga: Rp ${item['price'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Benchmark: ${item['benchmark'] ?? '-'}'),
        ],
      ),
    );
  }
}
