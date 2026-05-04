import '../../widgets/smart_image.dart';
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/sensor_service.dart';
import '../ai_chat/ai_provider.dart';

class PartDetailPage extends StatefulWidget {
  const PartDetailPage({super.key, this.part});

  final Map<String, dynamic>? part;

  @override
  State<PartDetailPage> createState() => _PartDetailPageState();
}

class _PartDetailPageState extends State<PartDetailPage> {
  final SensorService _sensorService = SensorService();
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _rotation = 0.0;
  String? _aiText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gyroSub = _sensorService.gyroscopeStream().listen((event) {
      setState(() {
        _rotation = (_rotation + event.y / 50).clamp(-0.5, 0.5);
      });
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  Future<void> _askAi() async {
    setState(() {
      _loading = true;
      _aiText = null;
    });

    final ai = context.read<AiProvider>();
    final text = await ai.askAboutPart(widget.part ?? {});

    if (mounted) {
      setState(() {
        _aiText = text;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(part['name']?.toString() ?? 'Detail Komponen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SmartImage(
              url: _resolveImage(part),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Transform.rotate(
            angle: _rotation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(part['name']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Benchmark: ${part['benchmark'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Text('Harga: Rp ${part['price'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _askAi,
            child: const Text('Jelaskan Komponen Ini'),
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (_aiText != null) Text(_aiText!),
          const SizedBox(height: 24),
          const Text('Spesifikasi Teknis', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Divider(color: AppColors.secondary),
          const SizedBox(height: 12),
          _buildDetailRow('Brand', part['brand']),
          _buildDetailRow('Kategori', part['category']?.toString().toUpperCase()),
          _buildDetailRow('Spesifikasi Utama', part['specs']),
          if (part['socket'] != null) _buildDetailRow('Socket', part['socket']),
          if (part['tdp'] != null) _buildDetailRow('TDP', '${part['tdp']} Watt'),
          if (part['type'] != null) _buildDetailRow('Tipe Memory', part['type']),
          if (part['watt'] != null) _buildDetailRow('Kapasitas Daya', '${part['watt']} Watt'),
          if (part['ram_type'] != null) _buildDetailRow('Dukungan RAM', part['ram_type']),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  List<FlSpot> _mockTrend(dynamic base) {
    final value = (base as num?)?.toDouble() ?? 0.0;
    return List.generate(6, (i) {
      final factor = 0.9 + (i * 0.04);
      return FlSpot(i.toDouble(), value * factor);
    });
  }


  String _resolveImage(Map<String, dynamic> item) {
    final image = item['image']?.toString();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    const placeholders = {
      'cpu': 'https://via.placeholder.com/256?text=CPU',
      'gpu': 'https://via.placeholder.com/256?text=GPU',
      'ram': 'https://via.placeholder.com/256?text=RAM',
      'storage': 'https://via.placeholder.com/256?text=SSD',
      'motherboard': 'https://via.placeholder.com/256?text=MOBO',
      'psu': 'https://via.placeholder.com/256?text=PSU',
      'casing': 'https://via.placeholder.com/256?text=CASE',
      'cooler': 'https://via.placeholder.com/256?text=COOLER',
    };
    final category = item['category']?.toString() ?? 'cpu';
    return placeholders[category] ?? 'https://via.placeholder.com/256?text=PC+Part';
  }
}
