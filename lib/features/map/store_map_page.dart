import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import 'map_provider.dart';

class StoreMapPage extends StatefulWidget {
  const StoreMapPage({super.key});

  @override
  State<StoreMapPage> createState() => _StoreMapPageState();
}

class _StoreMapPageState extends State<StoreMapPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MapProvider>().loadStores();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.error != null) {
      return Scaffold(body: Center(child: Text(provider.error!)));
    }

    final center = LatLng(provider.lat ?? -6.2, provider.lon ?? 106.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Terdekat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 13),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_application_1',
          ),
          MarkerLayer(
            markers: provider.stores.map((store) {
              final lat = store['lat'] as num? ?? 0;
              final lon = store['lon'] as num? ?? 0;
              final name = (store['tags']?['name'] ?? 'Toko Komputer').toString();
              return Marker(
                point: LatLng(lat.toDouble(), lon.toDouble()),
                child: GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(name),
                      content: const Text('Toko komputer terdekat.'),
                    ),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.accent, size: 32),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
