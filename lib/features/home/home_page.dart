import '../../widgets/smart_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../widgets/part_card.dart';
import '../ai_chat/ai_chat_page.dart';
import '../ai_chat/gemini_chat_screen.dart';
import '../minigame/quiz_game_page.dart';
import '../parts/part_detail_page.dart';
import '../parts/parts_search_page.dart';
import 'home_provider.dart';
import 'build_detail_page.dart';
import '../builder/saved_builds_page.dart';
import '../sensor/sensor_demo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeProvider>().loadTrending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatPage()),
        ),
        child: const Icon(Icons.smart_toy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartsSearchPage()),
              ),
              decoration: const InputDecoration(
                hintText: 'Cari komponen, brand, atau benchmark',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Build Unggulan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeaturedItem(
                    context,
                    'Entry Level Gaming',
                    'Cocok untuk 1080p gaming enteng.',
                    'Rp 7-9 jt',
                    'https://images.pexels.com/photos/7915357/pexels-photo-7915357.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    {
                      'cpu': {'name': 'Ryzen 3 4100', 'brand': 'AMD', 'price': 1000000},
                      'gpu': {'name': 'GTX 1650', 'brand': 'NVIDIA', 'price': 2500000},
                      'ram': {'name': 'Crucial 8GB', 'brand': 'Crucial', 'price': 400000},
                    },
                  ),
                  _buildFeaturedItem(
                    context,
                    'Mid-Range Powerhouse',
                    'Pilihan terbaik untuk 1440p gaming.',
                    'Rp 15-20 jt',
                    'https://images.pexels.com/photos/777001/pexels-photo-777001.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    {
                      'cpu': {'name': 'Ryzen 5 5600', 'brand': 'AMD', 'price': 2100000},
                      'gpu': {'name': 'RTX 4060 Ti', 'brand': 'NVIDIA', 'price': 6500000},
                      'ram': {'name': 'Vengeance 16GB', 'brand': 'Corsair', 'price': 800000},
                    },
                  ),
                  _buildFeaturedItem(
                    context,
                    'Ultimate 4K Beast',
                    'Performa tanpa kompromi.',
                    'Rp 40-50 jt',
                    'https://images.pexels.com/photos/1038916/pexels-photo-1038916.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    {
                      'cpu': {'name': 'Core i9-13900K', 'brand': 'Intel', 'price': 9000000},
                      'gpu': {'name': 'RTX 4090', 'brand': 'NVIDIA', 'price': 31000000},
                      'ram': {'name': 'Dominator 32GB', 'brand': 'Corsair', 'price': 2500000},
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizGamePage()),
              ),
              icon: const Icon(Icons.videogame_asset),
              label: const Text('Main Mini Game PC Quiz'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedBuildsPage()),
              ),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Koleksi Build Saya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SensorDemoPage()),
              ),
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Showcase PC 3D (Gyro)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? Text(provider.error!, style: const TextStyle(color: AppColors.error))
                      : ListView.separated(
                          itemCount: provider.trendingParts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = provider.trendingParts[index] as Map<String, dynamic>;
                            return PartCard(
                              name: item['name']?.toString() ?? 'Komponen',
                              brand: item['brand']?.toString() ?? 'Brand',
                              price: CurrencyHelper.format(item['price'] as num?),
                              imageUrl: _resolveImage(item),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PartDetailPage(part: item)),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedItem(
    BuildContext context,
    String name,
    String desc,
    String price,
    String imageUrl,
    Map<String, dynamic> parts,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildDetailPage(
            name: name,
            description: desc,
            totalPrice: price,
            parts: parts,
          ),
        ),
      ),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SmartImage(
                url: imageUrl,
                width: 220,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImage(Map<String, dynamic> item) {
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
    final category = item['category']?.toString() ?? 'cpu';
    return placeholders[category] ?? 'https://via.placeholder.com/128?text=PC+Part';
  }
}
