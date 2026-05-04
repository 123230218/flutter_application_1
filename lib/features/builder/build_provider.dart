import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/notification_helper.dart';
import 'compatibility_checker.dart';

class BuildProvider extends ChangeNotifier {
  final Map<String, dynamic> build = {};
  bool isLoading = false;
  String? error;
  String? aiMessage;

  double get totalPrice {
    double total = 0;
    for (final item in build.values) {
      if (item is Map<String, dynamic>) {
        total += (item['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  void setPart(String category, Map<String, dynamic> part) {
    build[category] = part;
    notifyListeners();
  }

  Future<void> randomizeBuild(int budget) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final random = Random();
      build.clear();
      double remaining = budget.toDouble();

      // Alokasi target (persentase)
      // GPU: 40%, CPU: 20%, Mobo: 10%, RAM: 8%, Sisanya: 22%
      
      // 1. Pilih CPU (Target 20% budget)
      final cpuParts = await ApiService.instance.fetchParts('cpu');
      final cpuTarget = budget * 0.20;
      var cpuCandidates = cpuParts.where((p) => (p['price'] as num) <= cpuTarget).toList();
      if (cpuCandidates.isEmpty) cpuCandidates = cpuParts;
      
      // Sort by price descending to get high-end parts for high budget
      cpuCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      // Ambil 3 teratas dan acak (agar tidak selalu sama tapi tetap high-end)
      final selectedCpu = Map<String, dynamic>.from(cpuCandidates[random.nextInt(min(3, cpuCandidates.length))]);
      build['cpu'] = selectedCpu;
      remaining -= selectedCpu['price'];

      // 2. Pilih Motherboard (Target 10% budget, Sesuai Socket CPU)
      final moboParts = await ApiService.instance.fetchParts('motherboard');
      final moboTarget = budget * 0.12;
      var moboCandidates = moboParts.where((p) => 
        (p['price'] as num) <= moboTarget && 
        p['socket'] == selectedCpu['socket']
      ).toList();
      
      if (moboCandidates.isEmpty) {
        moboCandidates = moboParts.where((p) => p['socket'] == selectedCpu['socket']).toList();
      }
      
      if (moboCandidates.isEmpty) moboCandidates = moboParts;
      
      moboCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      final selectedMobo = Map<String, dynamic>.from(moboCandidates[random.nextInt(min(2, moboCandidates.length))]);
      build['motherboard'] = selectedMobo;
      remaining -= selectedMobo['price'];

      // 3. Pilih RAM (Target 8% budget, Sesuai Tipe RAM Motherboard)
      final ramParts = await ApiService.instance.fetchParts('ram');
      final ramType = build['motherboard']['ram_type'] ?? 'DDR4';
      final ramTarget = budget * 0.08;
      var ramCandidates = ramParts.where((p) => p['type'] == ramType && (p['price'] as num) <= ramTarget).toList();
      
      if (ramCandidates.isEmpty) ramCandidates = ramParts.where((p) => p['type'] == ramType).toList();
      if (ramCandidates.isEmpty) ramCandidates = ramParts; 
      
      ramCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      final selectedRam = Map<String, dynamic>.from(ramCandidates[random.nextInt(min(2, ramCandidates.length))]);
      build['ram'] = selectedRam;
      remaining -= selectedRam['price'];

      // 4. Pilih GPU (Prioritas Utama, Sisanya dikurangi sedikit untuk part lain)
      final gpuParts = await ApiService.instance.fetchParts('gpu');
      // Sisakan minimal 3-5 jt untuk sisa part (casing, psu, dll)
      double gpuBudget = max(remaining - 3000000, remaining * 0.7);
      var gpuCandidates = gpuParts.where((p) => (p['price'] as num) <= gpuBudget).toList();
      if (gpuCandidates.isEmpty) gpuCandidates = gpuParts;
      
      gpuCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      final selectedGpu = Map<String, dynamic>.from(gpuCandidates[random.nextInt(min(3, gpuCandidates.length))]);
      build['gpu'] = selectedGpu;
      remaining -= selectedGpu['price'];

      // 5. Pilih Cooler (Berdasarkan TDP CPU)
      final coolerParts = await ApiService.instance.fetchParts('cooler');
      final cpuTdp = (selectedCpu['tdp'] as num? ?? 65).toInt();
      
      var coolerCandidates = coolerParts.where((p) {
        final price = p['price'] as num;
        if (cpuTdp > 120) return price > 1000000; // i9/Ryzen 9 butuh AIO/High Air
        if (cpuTdp > 65) return price > 300000;   // Mid range
        return true; // Low power boleh apa saja
      }).toList();
      
      if (coolerCandidates.isEmpty) coolerCandidates = coolerParts;
      coolerCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      final selectedCooler = Map<String, dynamic>.from(coolerCandidates[random.nextInt(min(2, coolerCandidates.length))]);
      build['cooler'] = selectedCooler;
      remaining -= selectedCooler['price'];

      // 6. Pilih Part Lain (Storage, Casing)
      final otherCats = ['storage', 'casing'];
      for (final cat in otherCats) {
        final parts = await ApiService.instance.fetchParts(cat);
        final partBudget = remaining / (otherCats.length + 1);
        var candidates = parts.where((p) => (p['price'] as num) <= partBudget).toList();
        if (candidates.isEmpty) candidates = parts;
        
        candidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        final pick = Map<String, dynamic>.from(candidates[random.nextInt(min(2, candidates.length))]);
        build[cat] = pick;
        remaining -= pick['price'];
      }

      // 7. PSU (Harus cukup Wattage + Efisiensi)
      final psuParts = await ApiService.instance.fetchParts('psu');
      final totalTdp = _calculateTotalTdp();
      // Gunakan buffer 1.5x untuk PSU agar awet dan stabil
      final minWatt = (totalTdp * 1.5).round();
      var psuCandidates = psuParts.where((p) => (p['watt'] as num? ?? 0) >= minWatt).toList();
      
      if (psuCandidates.isEmpty) psuCandidates = psuParts;

      // Ambil yang paling sesuai budget sisa tapi tetap berkualitas
      psuCandidates.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
      final selectedPsu = Map<String, dynamic>.from(psuCandidates.first);
      build['psu'] = selectedPsu;

    } catch (e) {
      print('Error randomizing: $e');
      error = 'Gagal membuat build cerdas. Pastikan data komponen lengkap.';
    }

    isLoading = false;
    notifyListeners();
  }

  int _calculateTotalTdp() {
    int total = 0;
    // CPU + GPU adalah pemakan daya terbesar
    final cpu = build['cpu'] as Map<String, dynamic>?;
    final gpu = build['gpu'] as Map<String, dynamic>?;
    
    total += (cpu?['tdp'] as num? ?? 65).toInt();
    total += (gpu?['tdp'] as num? ?? 200).toInt();
    
    // Tambahan 50W untuk part lain
    return total + 50;
  }

  Map<String, String> checkCompatibility() {
    return CompatibilityChecker.check(build);
  }

  List<Map<String, dynamic>> savedBuilds = [];

  Future<void> fetchSavedBuilds(int userId) async {
    savedBuilds = await DatabaseService.instance.getSavedBuilds(userId);
    notifyListeners();
  }

  Future<void> saveCurrentBuild(int userId, String name) async {
    if (build.isEmpty) return;
    
    String finalName = name;
    if (finalName.isEmpty) {
      int maxNum = 0;
      for (var b in savedBuilds) {
        final bName = b['name']?.toString() ?? '';
        if (bName.startsWith('Build Saya ')) {
          final numStr = bName.replaceFirst('Build Saya ', '');
          final n = int.tryParse(numStr);
          if (n != null && n > maxNum) maxNum = n;
        }
      }
      finalName = 'Build Saya ${maxNum + 1}';
    }
    
    await DatabaseService.instance.saveBuild(userId, finalName, Map<String, dynamic>.from(build));
    await fetchSavedBuilds(userId);
    await NotificationHelper.showBuildSaved(finalName);
  }

  Future<void> deleteBuild(int userId, int buildId) async {
    await DatabaseService.instance.deleteBuild(buildId);
    await fetchSavedBuilds(userId);
  }
}
