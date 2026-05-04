import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';

class MapProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  bool isLoading = false;
  String? error;
  double? lat;
  double? lon;
  List<Map<String, dynamic>> stores = [];

  Future<void> loadStores() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      lat = position.latitude;
      lon = position.longitude;
      stores = await ApiService.instance.fetchNearbyStores(lat!, lon!);
    } catch (e) {
      error = 'Gagal memuat lokasi toko.';
    }

    isLoading = false;
    notifyListeners();
  }
}
