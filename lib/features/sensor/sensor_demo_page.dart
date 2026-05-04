import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/services/sensor_service.dart';
import '../../core/constants/app_colors.dart';

class SensorDemoPage extends StatefulWidget {
  const SensorDemoPage({super.key});

  @override
  State<SensorDemoPage> createState() => _SensorDemoPageState();
}

class _SensorDemoPageState extends State<SensorDemoPage> {
  final SensorService _sensorService = SensorService();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  AccelerometerEvent? _accel;
  
  double xAngle = 0;
  double yAngle = 0;

  @override
  void initState() {
    super.initState();
    // Gunakan accelerometer untuk mendapatkan orientasi (tilt) yang stabil
    _accelSub = _sensorService.accelerometerStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _accel = event;
        // Hitung sudut kemiringan (radians)
        // x mendeteksi kemiringan kiri/kanan, y mendeteksi depan/belakang
        xAngle = (event.y / 10) * 0.5; // Batasi kemiringan agar tidak terlalu ekstrem
        yAngle = (event.x / 10) * -0.5;
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Builder 3D Sensor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Efek 3D Card
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Perspektif
                  ..rotateX(xAngle)
                  ..rotateY(yAngle),
                alignment: FractionalOffset.center,
                child: Container(
                  width: 250,
                  height: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Colors.white24, Colors.white10],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: -10,
                        offset: Offset(yAngle * 50, xAngle * 50),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Glassmorphism Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        // Konten Card
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.computer, size: 80, color: Colors.white),
                              const SizedBox(height: 20),
                              const Text(
                                'ULTRA PC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'RTX 4090 EDITION',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Efek Kilauan (Glow) yang bergerak
                        Positioned(
                          top: -100 + (xAngle * 100),
                          left: -100 + (yAngle * 100),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Text(
                'Miringkan ponsel Anda untuk melihat efek 3D',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SensorBadge(label: 'X', value: _accel?.x ?? 0),
                  const SizedBox(width: 10),
                  _SensorBadge(label: 'Y', value: _accel?.y ?? 0),
                  const SizedBox(width: 10),
                  _SensorBadge(label: 'Z', value: _accel?.z ?? 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorBadge extends StatelessWidget {
  final String label;
  final double value;
  const _SensorBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
