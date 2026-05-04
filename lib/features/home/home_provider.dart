import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<dynamic> trendingParts = [];

  Future<void> loadTrending() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final cpu = await ApiService.instance.fetchParts('cpu');
      trendingParts = cpu.take(5).toList();
    } catch (e) {
      error = 'Gagal memuat data trending.';
    }

    isLoading = false;
    notifyListeners();
  }
}
