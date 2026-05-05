import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class LlmService {
  static const String _geminiModel = 'gemini-flash-latest';
  String _debugInfo = '';

  Future<String> sendPrompt(String prompt, {List<Map<String, String>>? history}) async {
    _debugInfo = '';

    if (ApiConstants.geminiApiKey.isEmpty) {
      _debugInfo = 'API Key Gemini kosong di ApiConstants.dart';
      return _getFallbackResponse(prompt);
    }

    try {
      final result = await _callGemini(prompt, history);
      if (result != null) return _addSuggestions(result);
    } catch (e) {
      _debugInfo = 'Error Koneksi: $e';
      print('Gemini Error: $e');
    }

    return _getFallbackResponse(prompt);
  }

  Future<String?> _callGemini(String prompt, List<Map<String, String>>? history) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=${ApiConstants.geminiApiKey}');

    const systemInstruction = 
        'Kamu ARIA, pakar PC 2024. FOKUS: Rekomendasi PC rakitan Indonesia.\n'
        'Format: 1.Ringkasan 2.Komponen 3.Harga 4.Analisis.';

    List<Map<String, dynamic>> contents = [];
    
    if (history != null && history.isNotEmpty) {
      // Batasi riwayat hanya 5 pesan terakhir (paling hemat)
      final limitedHistory = history.length > 5 
          ? history.sublist(history.length - 5) 
          : history;

      for (var msg in limitedHistory) {
        if (msg['text'] == prompt && limitedHistory.last == msg) continue;

        contents.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': msg['text'] ?? ''}]
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}]
    });

    int retryCount = 0;
    http.Response? response;

    while (retryCount < 3) {
      try {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemInstruction}
              ]
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 2048,
            }
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        } else if (response.statusCode == 429) {
          retryCount++;
          print('Gemini 429: Retrying... ($retryCount/3)');
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        } else {
          _debugInfo = 'Status API: ${response.statusCode}';
          print('Gemini failed: ${response.body}');
          return null;
        }
      } catch (e) {
        _debugInfo = 'Error Koneksi: $e';
        print('Gemini call error: $e');
        return null;
      }
    }

    if (response?.statusCode == 429) {
      _debugInfo = 'LIMIT_KUOTA: Kuota harian Gemini Anda telah habis atau terlalu banyak permintaan dalam waktu singkat.';
    }
    return null;
  }

  String _addSuggestions(String text) {
    if (text.contains('Tanyakan ARIA')) return text;
    return '$text\n\n---\n**Tanyakan ARIA selanjutnya:**\n'
        '• "Apa komponen terbaik budget ini?"\n'
        '• "Cek bottleneck build ini?"';
  }

  String _getFallbackResponse(String prompt) {
    String errorHint = '';
    if (_debugInfo.contains('LIMIT_KUOTA')) {
      return '🤖 **ARIA (Sistem Sibuk):**\n\nMaaf, saat ini saya menerima terlalu banyak permintaan atau kuota gratis API Gemini Anda telah mencapai batas.\n\n**Saran:**\n1. Tunggu sekitar 1-2 menit sebelum mencoba lagi.\n2. Pastikan koneksi internet stabil.\n3. Gunakan API Key Gemini yang berbeda jika masalah berlanjut.';
    }
    
    if (_debugInfo.isNotEmpty) {
      errorHint = '\n\n**Analisis Masalah:**\n$_debugInfo';
    }
    return '🤖 **ARIA (Mode Analisis Gemini):**\nMaaf, sistem tidak merespon.$errorHint\n\n---\n**Saran:** Cek koneksi internet atau coba beberapa saat lagi.';
  }
}
