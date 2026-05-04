import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../auth/auth_provider.dart';
import 'build_provider.dart';

class SavedBuildsPage extends StatefulWidget {
  const SavedBuildsPage({super.key});

  @override
  State<SavedBuildsPage> createState() => _SavedBuildsPageState();
}

class _SavedBuildsPageState extends State<SavedBuildsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<BuildProvider>().fetchSavedBuilds(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuildProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: provider.savedBuilds.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada build yang disimpan.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.savedBuilds.length,
              itemBuilder: (context, index) {
                final build = provider.savedBuilds[index];
                Map<String, dynamic> parts = {};
                if (build['parts'] is String) {
                  parts = jsonDecode(build['parts'] as String) as Map<String, dynamic>;
                } else if (build['parts'] is Map) {
                  parts = Map<String, dynamic>.from(build['parts'] as Map);
                }

                double totalPrice = 0;
                parts.forEach((key, value) {
                  totalPrice += (value['price'] as num? ?? 0).toDouble();
                });

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              build['name'] ?? 'Build Tanpa Nama',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              _formatDate(build['created_at']),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${parts.length} Komponen',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${CurrencyHelper.format(totalPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                final provider = context.read<BuildProvider>();
                                parts.forEach((key, value) {
                                  provider.setPart(key, Map<String, dynamic>.from(value));
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Build dimuat ke perakit!')),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Gunakan Build'),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _confirmDelete(context, auth.userId!, build['id']),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'Hapus Build',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int userId, int buildId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Build?'),
        content: const Text('Apakah Anda yakin ingin menghapus build ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<BuildProvider>().deleteBuild(userId, buildId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Build berhasil dihapus.')),
      );
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
