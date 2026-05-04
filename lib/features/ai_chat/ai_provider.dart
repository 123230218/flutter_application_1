import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../core/services/llm_service.dart';

class AiProvider extends ChangeNotifier {
  final LlmService _service = LlmService();
  bool isLoading = false;
  List<Map<String, String>> messages = [];
  
  // Cache sederhana untuk menghindari pemanggilan berulang
  final Map<String, String> _cache = {};
  DateTime? _lastRequestTime;

  Future<void> loadHistory() async {
    final box = await Hive.openBox('ai_chat_history');
    final storedMessages = box.get('messages') as List?;
    if (storedMessages == null || storedMessages.isEmpty) {
      messages = [
        {
          'role': 'ai',
          'text': 'Halo! Saya **ARIA**, pakar spesialis PC Rakitan Anda.\n\n'
              'Ada yang bisa saya bantu hari ini? Anda bisa menanyakan rekomendasi rakitan berdasarkan budget, '
              'cek kompatibilitas komponen, atau bertanya detail spesifikasi hardware.'
        }
      ];
    } else {
      messages = storedMessages
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    
    // Proteksi Spam: Jangan kirim jika baru saja kirim (dalam 3 detik)
    if (_lastRequestTime != null && 
        DateTime.now().difference(_lastRequestTime!).inSeconds < 3) {
      return;
    }
    _lastRequestTime = DateTime.now();

    messages.add({'role': 'user', 'text': text});
    notifyListeners();

    isLoading = true;
    notifyListeners();

    final response = await _service.sendPrompt(text, history: messages);
    messages.add({'role': 'ai', 'text': response});

    isLoading = false;
    notifyListeners();

    final box = await Hive.openBox('ai_chat_history');
    await box.put('messages', messages);
  }

  Future<String> askRecommendation(String budget) async {
    final cacheKey = 'rec_$budget';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final prompt = 'Saya punya budget Rp $budget. Berikan rekomendasi spesifikasi PC gaming terbaik '
        'untuk budget tersebut. Sebutkan nama komponen (CPU, GPU, RAM, dll) dan estimasi harganya.';
    
    final response = await _service.sendPrompt(prompt);
    if (!response.contains('Sistem Sibuk')) {
      _cache[cacheKey] = response;
    }
    return response;
  }

  Future<String> askAboutPart(Map<String, dynamic> part) async {
    final name = part['name'] ?? 'unknown';
    final cacheKey = 'part_$name';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final prompt = 'Jelaskan komponen $name dengan bahasa sederhana.';
    final response = await _service.sendPrompt(prompt);
    if (!response.contains('Sistem Sibuk')) {
      _cache[cacheKey] = response;
    }
    return response;
  }

  Future<String> askCompatibility(Map<String, dynamic> build) async {
    final prompt = 'Cek apakah komponen-komponen ini kompatibel satu sama lain dan beri saran perbaikan jika ada: $build';
    return _service.sendPrompt(prompt);
  }
}
