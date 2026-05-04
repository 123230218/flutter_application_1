import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/part_card.dart';
import 'part_detail_page.dart';
import 'parts_provider.dart';

class PartsSearchPage extends StatefulWidget {
  const PartsSearchPage({super.key});

  @override
  State<PartsSearchPage> createState() => _PartsSearchPageState();
}

class _PartsSearchPageState extends State<PartsSearchPage> {
  final _searchController = TextEditingController();
  final _brandController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _minBenchmarkController = TextEditingController();
  String _sort = 'harga_asc';
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
  void dispose() {
    _searchController.dispose();
    _brandController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minBenchmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Komponen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari komponen',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => provider.applySearch(
                value,
                sort: _sort,
                brand: _brandController.text,
                minPrice: double.tryParse(_minPriceController.text),
                maxPrice: double.tryParse(_maxPriceController.text),
                minBenchmark: double.tryParse(_minBenchmarkController.text),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
              onChanged: (_) => provider.applySearch(
                _searchController.text,
                sort: _sort,
                brand: _brandController.text,
                minPrice: double.tryParse(_minPriceController.text),
                maxPrice: double.tryParse(_maxPriceController.text),
                minBenchmark: double.tryParse(_minBenchmarkController.text),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga min'),
                    onChanged: (_) => provider.applySearch(
                      _searchController.text,
                      sort: _sort,
                      brand: _brandController.text,
                      minPrice: double.tryParse(_minPriceController.text),
                      maxPrice: double.tryParse(_maxPriceController.text),
                      minBenchmark: double.tryParse(_minBenchmarkController.text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga max'),
                    onChanged: (_) => provider.applySearch(
                      _searchController.text,
                      sort: _sort,
                      brand: _brandController.text,
                      minPrice: double.tryParse(_minPriceController.text),
                      maxPrice: double.tryParse(_maxPriceController.text),
                      minBenchmark: double.tryParse(_minBenchmarkController.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _minBenchmarkController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Benchmark minimal'),
              onChanged: (_) => provider.applySearch(
                _searchController.text,
                sort: _sort,
                brand: _brandController.text,
                minPrice: double.tryParse(_minPriceController.text),
                maxPrice: double.tryParse(_maxPriceController.text),
                minBenchmark: double.tryParse(_minBenchmarkController.text),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Urutkan'),
              items: const [
                DropdownMenuItem(value: 'harga_asc', child: Text('Harga naik')),
                DropdownMenuItem(value: 'harga_desc', child: Text('Harga turun')),
                DropdownMenuItem(value: 'nama', child: Text('Nama A-Z')),
                DropdownMenuItem(value: 'benchmark', child: Text('Benchmark terbaik')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sort = value);
                provider.applySearch(
                  _searchController.text,
                  sort: value,
                  brand: _brandController.text,
                  minPrice: double.tryParse(_minPriceController.text),
                  maxPrice: double.tryParse(_maxPriceController.text),
                  minBenchmark: double.tryParse(_minBenchmarkController.text),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filtered.isEmpty
                    ? const Center(child: Text('Tidak ada hasil.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = provider.filtered[index];
                          return PartCard(
                            name: item['name']?.toString() ?? 'Komponen',
                            brand: item['brand']?.toString() ?? '-',
                            price: 'Rp ${item['price'] ?? '-'}',
                            imageUrl: _resolveImage(item, _category),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PartDetailPage(part: item)),
                            ),
                          );
                        },
                      ),
          ),
          FutureBuilder<List<String>>(
            future: provider.getSearchHistory(),
            builder: (context, snapshot) {
              final history = snapshot.data ?? [];
              if (history.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: history
                      .map((item) => ActionChip(
                            label: Text(item),
                            onPressed: () {
                              _searchController.text = item;
                              provider.applySearch(item, sort: _sort);
                            },
                          ))
                      .toList(),
                ),
              );
            },
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(provider.error!, style: const TextStyle(color: AppColors.error)),
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
