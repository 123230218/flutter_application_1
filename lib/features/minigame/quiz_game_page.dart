import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/services/database_service.dart';
import '../../core/services/sensor_service.dart';
import '../../core/utils/notification_helper.dart';
import '../auth/auth_provider.dart';

class QuizGamePage extends StatefulWidget {
  const QuizGamePage({super.key});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _questionBank = [
    {'q': 'Apa fungsi PSU?', 'a': ['Menyimpan data', 'Menyuplai daya', 'Memproses grafis', 'Pendingin'], 'c': 1},
    {'q': 'SSD lebih cepat karena?', 'a': ['Tidak ada bagian bergerak', 'Lebih besar', 'Pakai kipas', 'Bahan metal'], 'c': 0},
    {'q': 'Socket CPU menentukan?', 'a': ['Jenis RAM', 'Kompatibilitas CPU', 'Warna casing', 'Jenis PSU'], 'c': 1},
    {'q': 'GPU singkatan dari?', 'a': ['General Power Unit', 'Graphics Processing Unit', 'Gaming Performance Unit', 'Graphic Power Utility'], 'c': 1},
    {'q': 'RAM berfungsi untuk?', 'a': ['Penyimpanan permanen', 'Memori sementara', 'Mengirim listrik', 'Mendinginkan CPU'], 'c': 1},
    {'q': 'Motherboard adalah?', 'a': ['Penyimpanan', 'Pusat koneksi komponen', 'Kartu grafis', 'Power supply'], 'c': 1},
    {'q': 'TDP adalah?', 'a': ['Total Data Processing', 'Thermal Design Power', 'Time Delay Power', 'Turbo Data Power'], 'c': 1},
    {'q': 'Cooler berfungsi untuk?', 'a': ['Menambah FPS', 'Mendinginkan CPU/GPU', 'Menambah RAM', 'Menyuplai daya'], 'c': 1},
    {'q': 'PSU 80+ berarti?', 'a': ['Kualitas efisiensi', 'Jumlah kabel', 'Jumlah kipas', 'Ukuran casing'], 'c': 0},
    {'q': 'NVMe adalah?', 'a': ['Jenis RAM', 'Interface SSD', 'Jenis GPU', 'Jenis CPU'], 'c': 1},
    {'q': 'PCIe digunakan untuk?', 'a': ['Port USB', 'Slot ekspansi', 'Audio jack', 'Power'], 'c': 1},
    {'q': 'Dual channel RAM artinya?', 'a': ['Dua PSU', 'Dua stik RAM', 'Dua GPU', 'Dua monitor'], 'c': 1},
    {'q': 'VRAM terdapat pada?', 'a': ['CPU', 'GPU', 'PSU', 'SSD'], 'c': 1},
    {'q': 'M.2 biasanya untuk?', 'a': ['RAM', 'SSD', 'GPU', 'PSU'], 'c': 1},
    {'q': 'Benchmark digunakan untuk?', 'a': ['Uji performa', 'Uji suhu', 'Uji warna', 'Uji suara'], 'c': 0},
    {'q': 'Overclock artinya?', 'a': ['Mempercepat komponen', 'Memperbesar casing', 'Menambah RAM', 'Mengurangi daya'], 'c': 0},
    {'q': 'Fan curve adalah?', 'a': ['Grafik suhu', 'Pengaturan kecepatan kipas', 'Kecepatan CPU', 'Kapasitas PSU'], 'c': 1},
    {'q': 'SATA biasa untuk?', 'a': ['SSD/HDD', 'GPU', 'RAM', 'CPU'], 'c': 0},
    {'q': 'BIOS digunakan untuk?', 'a': ['Game', 'Mengatur hardware', 'Streaming', 'Editing'], 'c': 1},
    {'q': 'Thermal paste untuk?', 'a': ['Menempel RAM', 'Menghantarkan panas', 'Mengurangi daya', 'Menghapus debu'], 'c': 1},
    {'q': 'ATX adalah?', 'a': ['Tipe casing/mobo', 'Tipe GPU', 'Tipe RAM', 'Tipe SSD'], 'c': 0},
    {'q': 'RGB berfungsi untuk?', 'a': ['Performa', 'Estetika', 'Daya', 'Suhu'], 'c': 1},
    {'q': 'Bottleneck artinya?', 'a': ['Komponen menghambat performa', 'Suhu rendah', 'FPS tinggi', 'Harga murah'], 'c': 0},
    {'q': 'Chipset motherboard menentukan?', 'a': ['Fitur mobo', 'Warna casing', 'Jenis PSU', 'Jenis monitor'], 'c': 0},
    {'q': 'PSU modular artinya?', 'a': ['Kabel bisa dilepas', 'Lebih kuat', 'Lebih kecil', 'Lebih panas'], 'c': 0},
    {'q': 'RAM DDR4 vs DDR5?', 'a': ['Beda generasi', 'Beda warna', 'Beda PSU', 'Beda casing'], 'c': 0},
    {'q': 'CPU core menentukan?', 'a': ['Jumlah tugas paralel', 'Warna RGB', 'Kecepatan kipas', 'Ukuran casing'], 'c': 0},
    {'q': 'Monitor 144Hz cocok untuk?', 'a': ['Gaming', 'Office', 'Server', 'NAS'], 'c': 0},
    {'q': 'GPU driver fungsi?', 'a': ['Optimasi performa', 'Menambah storage', 'Menghapus RAM', 'Mengganti PSU'], 'c': 0},
    {'q': 'Ray tracing adalah?', 'a': ['Teknik rendering', 'Jenis PSU', 'Jenis SSD', 'Jenis CPU'], 'c': 0},
  ];

  late List<Map<String, dynamic>> _questions;
  int _index = 0;
  int _score = 0;
  int _timeLeft = 15;
  Timer? _timer;
  bool _isCorrect = false;
  bool _isWrong = false;
  int _skipUsed = 0;
  late ConfettiController _confetti;
  final SensorService _sensorService = SensorService();
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _questions = List<Map<String, dynamic>>.from(_questionBank)..shuffle();
    _questions = _questions.take(10).toList();
    _startTimer();
    _accelSub = _sensorService.accelerometerStream().listen((event) {
      final magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      if (magnitude > 15 && _skipUsed < 2) {
        _skipUsed += 1;
        _nextQuestion();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft -= 1;
      });
      if (_timeLeft <= 0) {
        _score -= 5;
        _nextQuestion();
      }
    });
  }

  void _answer(int index) {
    final correct = _questions[_index]['c'] as int;
    final answeredFast = _timeLeft > 10;

    setState(() {
      _isCorrect = index == correct;
      _isWrong = index != correct;
    });

    if (index == correct) {
      _score += 10;
      if (answeredFast) {
        _score += 5;
      }
    }

    Future.delayed(const Duration(milliseconds: 500), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      _isCorrect = false;
      _isWrong = false;
    });

    if (_index == _questions.length - 1) {
      _finish();
    } else {
      setState(() => _index += 1);
      _startTimer();
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_score > 80) {
      _confetti.play();
      NotificationHelper.showAchievement('Skor quiz tinggi: $_score');
    }

    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      await DatabaseService.instance.saveQuizScore(auth.userId!, _score);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hasil Quiz'),
        content: Text('Skor: $_score\nGrade: ${_grade(_score)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  String _grade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'E';
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    final options = (question['a'] as List).cast<String>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Quiz Master'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Pertanyaan ${_index + 1} dari ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                     Text('Waktu: $_timeLeft detik'),
                   ],
                 ),
                 const SizedBox(height: 8),
                 LinearProgressIndicator(
                   value: (_index + 1) / _questions.length,
                   backgroundColor: Colors.grey[200],
                   valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                 ),
                 const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: _isWrong
                      ? Matrix4.translationValues(8 * sin(_timeLeft.toDouble()), 0, 0)
                      : Matrix4.identity(),
                  child: Text(question['q'] as String, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return AnimatedScale(
                        scale: _isCorrect ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: () => _answer(index),
                          child: Text(options[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, Object?>>>(
                  future: DatabaseService.instance.getTopScores(),
                  builder: (context, snapshot) {
                    final scores = snapshot.data ?? [];
                    if (scores.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Leaderboard 5 Teratas:'),
                        ...scores.map((e) => Text('Skor: ${e['score']}')),
                      ],
                    );
                  },
                )
              ],
            ),
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
