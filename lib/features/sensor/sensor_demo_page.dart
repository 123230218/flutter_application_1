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

class _SensorDemoPageState extends State<SensorDemoPage>
    with TickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  AccelerometerEvent? _accel;

  double xAngle = 0;
  double yAngle = 0;

  late AnimationController _fanController;
  late AnimationController _rgbController;
  late Animation<double> _rgbAnimation;

  @override
  void initState() {
    super.initState();

    // Fan rotation animation
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    // RGB color cycle animation
    _rgbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _rgbAnimation = Tween<double>(begin: 0, end: 1).animate(_rgbController);

    _accelSub = _sensorService.accelerometerStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _accel = event;
        xAngle = (event.y / 10) * 0.5;
        yAngle = (event.x / 10) * -0.5;
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _fanController.dispose();
    _rgbController.dispose();
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
            colors: [Color(0xFF0A0A0F), Color(0xFF0F1923), Color(0xFF0A0A0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D GPU Card with RGB glow
              AnimatedBuilder(
                animation: _rgbAnimation,
                builder: (context, child) {
                  final hue = _rgbAnimation.value * 360;
                  final glowColor =
                      HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(xAngle)
                      ..rotateY(yAngle),
                    alignment: FractionalOffset.center,
                    child: Container(
                      width: 320,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: Offset(yAngle * 60, xAngle * 60),
                          ),
                          BoxShadow(
                            color: glowColor.withOpacity(0.2),
                            blurRadius: 80,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // GPU PCB Background
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _GpuPcbPainter(),
                              ),
                            ),
                            // GPU Cooler Cover
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _GpuCoolerPainter(
                                  rgbColor: glowColor,
                                  xAngle: xAngle,
                                  yAngle: yAngle,
                                ),
                              ),
                            ),
                            // Fan 1
                            Positioned(
                              left: 18,
                              top: 25,
                              child: AnimatedBuilder(
                                animation: _fanController,
                                builder: (_, __) => Transform.rotate(
                                  angle:
                                      _fanController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(100, 100),
                                    painter: _FanPainter(color: glowColor),
                                  ),
                                ),
                              ),
                            ),
                            // Fan 2
                            Positioned(
                              left: 110,
                              top: 25,
                              child: AnimatedBuilder(
                                animation: _fanController,
                                builder: (_, __) => Transform.rotate(
                                  angle:
                                      _fanController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(100, 100),
                                    painter: _FanPainter(color: glowColor),
                                  ),
                                ),
                              ),
                            ),
                            // Fan 3
                            Positioned(
                              left: 202,
                              top: 25,
                              child: AnimatedBuilder(
                                animation: _fanController,
                                builder: (_, __) => Transform.rotate(
                                  angle:
                                      _fanController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(100, 100),
                                    painter: _FanPainter(color: glowColor),
                                  ),
                                ),
                              ),
                            ),
                            // GPU Label (bottom-left)
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NVIDIA',
                                    style: TextStyle(
                                      color: glowColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const Text(
                                    'GeForce RTX\u2122',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const Text(
                                    '4090',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TDP Badge (top-right)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: glowColor.withOpacity(0.6)),
                                ),
                                child: Text(
                                  '450W TDP',
                                  style: TextStyle(
                                    color: glowColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Glassmorphism highlight
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.07),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // GPU spec badges
              AnimatedBuilder(
                animation: _rgbAnimation,
                builder: (context, _) {
                  final hue = _rgbAnimation.value * 360;
                  final c = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _SpecBadge(label: '24GB GDDR6X', color: c),
                      _SpecBadge(label: '384-bit', color: c),
                      _SpecBadge(label: '16384 CUDA', color: c),
                      _SpecBadge(label: '1008 GB/s', color: c),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Miringkan ponsel untuk efek 3D',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              const SizedBox(height: 16),
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

// ─────────── Custom Painters ───────────

class _GpuPcbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // PCB green background
    final paint = Paint()..color = const Color(0xFF0D1F0D);
    canvas.drawRect(Offset.zero & size, paint);

    // PCB horizontal trace lines
    final tracePaint = Paint()
      ..color = const Color(0xFF1A3A1A).withOpacity(0.8)
      ..strokeWidth = 0.8;
    for (double y = 6; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tracePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GpuCoolerPainter extends CustomPainter {
  final Color rgbColor;
  final double xAngle;
  final double yAngle;

  _GpuCoolerPainter({
    required this.rgbColor,
    required this.xAngle,
    required this.yAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Shroud dark metal background
    final shroudPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF1A1A1C),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    final shroudRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(14),
    );
    canvas.drawRRect(shroudRect, shroudPaint);

    // RGB strip – top
    final rgbPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          rgbColor,
          rgbColor.withOpacity(0.3),
          rgbColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, 4), rgbPaint);

    // RGB strip – bottom
    canvas.drawRect(
        Rect.fromLTWH(2, size.height - 6, size.width - 4, 4), rgbPaint);

    // Heatsink fin hints at the right edge
    final finPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5;
    for (double x = 305; x < size.width - 4; x += 4) {
      canvas.drawLine(Offset(x, 10), Offset(x, size.height - 10), finPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GpuCoolerPainter old) =>
      old.rgbColor != rgbColor ||
      old.xAngle != xAngle ||
      old.yAngle != yAngle;
}

class _FanPainter extends CustomPainter {
  final Color color;
  _FanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // Blades
    final bladePaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;
    final bladeBorderPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const bladeCount = 9;
    for (int i = 0; i < bladeCount; i++) {
      final angle = (i / bladeCount) * 2 * math.pi;
      final path = Path();
      final r1 = radius * 0.18;
      final r2 = radius * 0.85;
      final sweep = math.pi / bladeCount * 1.4;

      path.moveTo(
        center.dx + r1 * math.cos(angle),
        center.dy + r1 * math.sin(angle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: r2),
        angle - sweep / 2,
        sweep,
        false,
      );
      path.lineTo(center.dx, center.dy);
      path.close();

      canvas.drawPath(path, bladePaint);
      canvas.drawPath(path, bladeBorderPaint);
    }

    // Hub
    final hubPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.18, hubPaint);

    // Hub glow center
    final hubGlowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.08, hubGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _FanPainter old) => old.color != color;
}

// ─────────── Supporting Widgets ───────────

class _SpecBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SpecBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
