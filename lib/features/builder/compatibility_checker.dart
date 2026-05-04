class CompatibilityChecker {
  static Map<String, String> check(Map<String, dynamic> build) {
    final cpu = build['cpu'] as Map<String, dynamic>?;
    final mobo = build['motherboard'] as Map<String, dynamic>?;
    final ram = build['ram'] as Map<String, dynamic>?;
    final psu = build['psu'] as Map<String, dynamic>?;

    if (cpu != null && mobo != null) {
      final cpuSocket = cpu['socket'];
      final moboSocket = mobo['socket'];
      if (cpuSocket != null && moboSocket != null && cpuSocket != moboSocket) {
        return {'status': 'fail', 'message': 'Socket CPU dan motherboard tidak cocok.'};
      }
    }

    if (ram != null && mobo != null) {
      final ramType = ram['type'];
      final moboRam = mobo['ram_type'];
      if (ramType != null && moboRam != null && ramType != moboRam) {
        return {'status': 'fail', 'message': 'Tipe RAM tidak didukung motherboard.'};
      }
    }

    final totalTdp = _sumTdp(build);
    if (psu != null) {
      final psuWatt = psu['watt'] ?? 0;
      final required = (totalTdp * 1.2).round();
      if (psuWatt < required) {
        return {
          'status': 'fail',
          'message': 'PSU kurang kuat. Butuh minimal ${required}W.'
        };
      }
    }

    return {'status': 'ok', 'message': 'Build kompatibel.'};
  }

  static int _sumTdp(Map<String, dynamic> build) {
    int total = 0;
    for (final entry in build.values) {
      if (entry is Map<String, dynamic>) {
        total += (entry['tdp'] ?? 0) as int;
      }
    }
    return total;
  }
}
