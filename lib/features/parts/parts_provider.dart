import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:hive/hive.dart';

import '../../core/services/api_service.dart';

class PartsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> parts = [];
  List<Map<String, dynamic>> filtered = [];

  Future<void> loadParts(String category) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await ApiService.instance.fetchParts(category);
      parts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      filtered = List.from(parts);
    } catch (e) {
      error = 'Gagal memuat data komponen.';
    }

    isLoading = false;
    notifyListeners();
  }

  void applySearch(
    String query, {
    String? category,
    String? sort,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minBenchmark,
  }) {
    final lower = query.toLowerCase();
    filtered = parts.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final brandName = item['brand']?.toString().toLowerCase() ?? '';
      final score = partialRatio(lower, '$name $brandName');
      final matchesText = score > 50 || name.contains(lower) || brandName.contains(lower);
      final matchesBrand = brand == null || brand.isEmpty || brandName.contains(brand.toLowerCase());
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final benchmark = (item['benchmark'] as num?)?.toDouble() ?? 0.0;
      final matchesPrice = (minPrice == null || price >= minPrice) &&
          (maxPrice == null || price <= maxPrice);
      final matchesBenchmark = minBenchmark == null || benchmark >= minBenchmark;
      return matchesText && matchesBrand && matchesPrice && matchesBenchmark;
    }).toList();

    if (sort == 'harga_asc') {
      filtered.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (sort == 'harga_desc') {
      filtered.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (sort == 'nama') {
      filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (sort == 'benchmark') {
      filtered.sort((a, b) => (b['benchmark'] as num).compareTo(a['benchmark'] as num));
    }

    _saveSearchHistory(query);
    notifyListeners();
  }

  Future<List<String>> getSearchHistory() async {
    final box = await Hive.openBox('search_history');
    return (box.get('history') as List?)?.cast<String>() ?? [];
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.isEmpty) {
      return;
    }
    final box = await Hive.openBox('search_history');
    final history = (box.get('history') as List?)?.cast<String>() ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    await box.put('history', history);
  }
}
