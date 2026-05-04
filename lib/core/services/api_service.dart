import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../utils/notification_helper.dart';

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  final Dio _dio = Dio();

  Future<List<dynamic>> fetchParts(String category) async {
    print('ApiService: Mencoba memuat kategori: $category');
    
    Box? box;
    try {
      box = await Hive.openBox('parts_cache');
      // BYPASS CACHE FOR VISUAL UPDATE
      print('ApiService: Mengabaikan cache untuk pembaruan visual...');
    } catch (e) {
      print('ApiService: Gagal membuka Hive box: $e');
    }

    try {
      final response = await http.get(Uri.parse('${ApiConstants.partsBaseUrl}/$category'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (box != null) {
          final cacheKey = 'parts_$category';
          await box.put(cacheKey, {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': data,
          });
        }
        return data;
      }
    } catch (e) {
      print('ApiService: Gagal mengambil data online untuk $category: $e');
    }

    print('ApiService: Menggunakan data lokal (seed) untuk $category');

    try {
      final seed = await rootBundle.loadString('assets/data/parts_seed_v2.json');
      final seedData = jsonDecode(seed) as Map<String, dynamic>;
      final list = (seedData[category] as List<dynamic>? ?? []).toList();
      if (box != null) {
        final cacheKey = 'parts_$category';
        await box.put(cacheKey, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': list,
        });
      }
      return list;
    } catch (e) {
      print('ApiService: ERROR KRITIS saat memuat seed.json untuk $category: $e');
      return [];
    }
  }

  void _notifyPriceChanges(List<dynamic> oldData, List<dynamic> newData) {
    final oldMap = {
      for (final item in oldData)
        (item as Map)['name'].toString(): (item['price'] as num?)?.toDouble() ?? 0.0
    };

    for (final item in newData) {
      final map = item as Map;
      final name = map['name'].toString();
      final newPrice = (map['price'] as num?)?.toDouble() ?? 0.0;
      final oldPrice = oldMap[name];
      if (oldPrice != null && oldPrice != newPrice) {
        final direction = newPrice > oldPrice ? 'naik' : 'turun';
        NotificationHelper.showPriceAlert(
          'Harga $direction',
          '$name berubah menjadi Rp ${newPrice.toStringAsFixed(0)}',
        );
      }
    }
  }

  Future<Map<String, double>> fetchExchangeRates() async {
    final box = await Hive.openBox('exchange_rates');
    final cached = box.get('rates') as Map<String, dynamic>?;
    if (cached != null && _isFresh(cached['timestamp'] as int, const Duration(hours: 6))) {
      return (cached['data'] as Map).map((key, value) => MapEntry(key.toString(), value.toDouble()));
    }

    try {
      final response = await http.get(Uri.parse(ApiConstants.exchangeRateBaseUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = (json['conversion_rates'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        final updated = (json['time_last_update_unix'] as num?)?.toInt();
        await box.put('rates', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': rates,
        });
        if (updated != null) {
          await box.put('last_updated', updated);
        }
        return rates;
      }
    } catch (_) {
      // Ignore and fallback below
    }

    final fallback = {
      'USD': 1.0,
      'IDR': 15000.0,
      'EUR': 0.9,
      'JPY': 150.0,
      'GBP': 0.78,
    };
    await box.put('last_updated', DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return fallback;
  }

  Future<DateTime?> getExchangeRateLastUpdated() async {
    final box = await Hive.openBox('exchange_rates');
    final unix = box.get('last_updated') as int?;
    if (unix == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(unix * 1000);
  }

  Future<List<Map<String, dynamic>>> fetchNearbyStores(double lat, double lon) async {
    const queryTemplate = '[out:json];node["shop"="computer"](around:20000,lat,lon);out;';
    final query = queryTemplate.replaceAll('lat', lat.toString()).replaceAll('lon', lon.toString());

    try {
      final response = await _dio.post(
        ApiConstants.overpassUrl,
        data: query,
        options: Options(
          headers: {
            'Content-Type': 'text/plain',
            'User-Agent': 'PCBuilderAssistant/1.0 (contact@example.com)'
          },
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>;
        return elements.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {
      // Ignore, return empty list
    }

    return [];
  }

  bool _isFresh(int timestamp, Duration ttl) {
    final stored = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(stored) < ttl;
  }
}
