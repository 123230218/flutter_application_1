import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../widgets/part_card.dart';
import '../auth/auth_provider.dart';
import '../builder/build_provider.dart';
import 'compare_page.dart';
import 'part_detail_page.dart';
import 'parts_provider.dart';

class PartsListPage extends StatefulWidget {
  const PartsListPage({super.key});

  @override
  State<PartsListPage> createState() => _PartsListPageState();
}

class _PartsListPageState extends State<PartsListPage> {
  String _category = 'cpu';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<PartsProvider>().loadParts(_category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Komponen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'cpu', child: Text('CPU')),
                DropdownMenuItem(value: 'gpu', child: Text('GPU')),
                DropdownMenuItem(value: 'ram', child: Text('RAM')),
                DropdownMenuItem(value: 'storage', child: Text('Storage')),
                DropdownMenuItem(value: 'motherboard', child: Text('Motherboard')),
                DropdownMenuItem(value: 'psu', child: Text('PSU')),
                DropdownMenuItem(value: 'casing', child: Text('Casing')),
                DropdownMenuItem(value: 'cooler', child: Text('Cooler')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
                context.read<PartsProvider>().loadParts(value);
              },
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Text(provider.error!, style: const TextStyle(color: AppColors.error))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.parts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = provider.parts[index];
                          return Dismissible(
                            key: ValueKey(item['name']),
                            background: Container(color: AppColors.success),
                            secondaryBackground: Container(color: AppColors.secondary),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                context.read<BuildProvider>().setPart(
                                      _category,
                                      item,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ditambahkan ke build.')),
                                );
                              } else {
                                final auth = context.read<AuthProvider>();
                                if (auth.userId != null) {
                                  final partId = item['id'] ?? item['name'].hashCode;
                                  DatabaseService.instance.addFavorite(auth.userId!, partId as int);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ditambahkan ke favorit.')),
                                );
                              }
                              return false;
                            },
                            child: GestureDetector(
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => ListView(
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      ListTile(
                                        title: const Text('Lihat Detail'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PartDetailPage(part: item),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('Bandingkan'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const ComparePage(),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('Bagikan'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Share.share('Cek komponen ${item['name']}!');
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: PartCard(
                                name: item['name']?.toString() ?? 'Komponen',
                                brand: item['brand']?.toString() ?? '-',
                                price: CurrencyHelper.format(item['price'] as num?),
                                imageUrl: _resolveImage(item, _category),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartDetailPage(part: item),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _resolveImage(Map<String, dynamic> item, String fallbackCategory) {
    final image = item['image']?.toString();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    final category = item['category']?.toString() ?? fallbackCategory;
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
