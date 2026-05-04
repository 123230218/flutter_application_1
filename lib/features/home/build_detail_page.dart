import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/part_card.dart';
import '../builder/build_provider.dart';
import '../parts/part_detail_page.dart';

class BuildDetailPage extends StatelessWidget {
  const BuildDetailPage({
    super.key,
    required this.name,
    required this.description,
    required this.totalPrice,
    required this.parts,
  });

  final String name;
  final String description;
  final String totalPrice;
  final Map<String, dynamic> parts;

  @override
  Widget build(BuildContext context) {
    final categories = parts.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Estimasi Harga: $totalPrice',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final provider = context.read<BuildProvider>();
                    parts.forEach((category, part) {
                      provider.setPart(category, Map<String, dynamic>.from(part));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Build berhasil diimpor ke perakit!')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Impor ke Perakit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar Komponen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                final part = parts[category] as Map<String, dynamic>;
                return PartCard(
                  name: part['name']?.toString() ?? 'Komponen',
                  brand: part['brand']?.toString() ?? '-',
                  price: 'Rp ${part['price'] ?? '-'}',
                  imageUrl: _resolveImage(part, category),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartDetailPage(part: part)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _resolveImage(Map<String, dynamic> item, String category) {
    final image = item['image']?.toString();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    const placeholders = {
      'cpu': 'https://via.placeholder.com/128?text=CPU',
      'gpu': 'https://via.placeholder.com/128?text=GPU',
      'ram': 'https://via.placeholder.com/128?text=RAM',
      'storage': 'https://via.placeholder.com/128?text=SSD',
      'motherboard': 'https://via.placeholder.com/128?text=MOBO',
      'psu': 'https://via.placeholder.com/128?text=PSU',
      'casing': 'https://via.placeholder.com/128?text=CASE',
      'cooler': 'https://via.placeholder.com/128?text=COOLER',
    };
    return placeholders[category] ?? 'https://via.placeholder.com/128?text=PC+Part';
  }
}
