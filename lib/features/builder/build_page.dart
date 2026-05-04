import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../widgets/smart_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/sensor_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/notification_helper.dart';
import '../ai_chat/ai_provider.dart';
import '../parts/parts_list_page.dart';
import '../auth/auth_provider.dart';
import 'build_provider.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    final formatter = NumberFormat.decimalPattern('id_ID');
    String formatted = formatter.format(int.parse(newText));
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BuildPage extends StatefulWidget {
  const BuildPage({super.key});

  @override
  State<BuildPage> createState() => _BuildPageState();
}

class _BuildPageState extends State<BuildPage> {
  final _budgetController = TextEditingController(text: '15.000.000');
  late ConfettiController _confetti;
  StreamSubscription? _accelerometerSub;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  double _gyroX = 0, _gyroY = 0;
  StreamSubscription? _gyroSub;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    NotificationHelper.scheduleDailyReminder();
    _initSensors();
  }

  void _initSensors() {
    _accelerometerSub = accelerometerEventStream().listen((event) {
      final double acceleration = (event.x - _lastX).abs() + (event.y - _lastY).abs() + (event.z - _lastZ).abs();
      if (acceleration > 30) {
        _handleRandomize();
      }
      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });

    _gyroSub = gyroscopeEventStream().listen((event) {
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
      });
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _budgetController.dispose();
    _accelerometerSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  Future<void> _handleRandomize() async {
    final provider = context.read<BuildProvider>();
    // Hapus titik sebelum diparse ke int
    final budgetStr = _budgetController.text.replaceAll('.', '');
    final budget = int.tryParse(budgetStr) ?? 15000000;
    await provider.randomizeBuild(budget);
    _confetti.play();
  }

  Future<void> _askRecommendation() async {
    final ai = context.read<AiProvider>();
    final budget = _budgetController.text;
    final response = await ai.askRecommendation(budget);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rekomendasi ARIA'),
        content: Text(response),
      ),
    );
  }

  Future<void> _checkCompatibility() async {
    final provider = context.read<BuildProvider>();
    final result = provider.checkCompatibility();
    final ai = context.read<AiProvider>();
    final aiText = await ai.askCompatibility(provider.build);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hasil Kompatibilitas'),
        content: Text('${result['message']}\n\nAI: $aiText'),
      ),
    );
  }

  Future<void> _handleSaveBuild() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk menyimpan build.')),
      );
      return;
    }

    final provider = context.read<BuildProvider>();
    if (provider.build.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Build masih kosong.')),
      );
      return;
    }

    await provider.saveCurrentBuild(auth.userId!, 'Build Baru ${DateTime.now().hour}:${DateTime.now().minute}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Build berhasil disimpan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuildProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleRandomize(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Budget (IDR)',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartsListPage()),
                ),
                child: const Text('Tambah Komponen'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleRandomize,
                child: const Text('Buat Build Acak'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _askRecommendation,
                child: const Text('Minta Rekomendasi'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checkCompatibility,
                child: const Text('Cek Kompatibilitas'),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppColors.surface.withAlpha(128),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Column(
                        children: [
                          Icon(Icons.vibration, size: 16, color: AppColors.secondary),
                          Text('Shake to Randomize', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.explore, size: 16, color: AppColors.accent),
                          Text('Tilt: ${_gyroX.toStringAsFixed(1)}, ${_gyroY.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleRandomize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('CARI BUILD SESUAI BUDGET', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleSaveBuild,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                child: const Text('Simpan Build'),
              ),
              const SizedBox(height: 16),
              Text('Total harga: ${CurrencyHelper.format(provider.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (provider.isLoading) const LinearProgressIndicator(),
              if (provider.error != null)
                Text(provider.error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              ...provider.build.entries.map((entry) {
                final item = entry.value as Map<String, dynamic>;
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartImage(
                      url: item['image']?.toString(),
                      width: 48,
                      height: 48,
                    ),
                  ),
                  title: Text('${entry.key.toUpperCase()} - ${item['name'] ?? '-'}'),
                  subtitle: Text(CurrencyHelper.format(item['price'] as num?)),
                );
              }),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confetti),
          ),
        ],
      ),
    );
  }
}
