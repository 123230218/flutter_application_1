import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_constants.dart';

class LlmService {
  static const String _modelName = 'gemini-2.5-flash';

  Future<String> sendPrompt(String prompt, {List<Map<String, String>>? history}) async {
    if (ApiConstants.geminiApiKey.isEmpty || ApiConstants.geminiApiKey.contains('API_KEY')) {
      return '🤖 **ARIA:** API Key Gemini belum diatur atau tidak valid di ApiConstants.dart';
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: ApiConstants.geminiApiKey,
        systemInstruction: Content.system(
          'Kamu ARIA, pakar PC 2024. FOKUS: Rekomendasi PC rakitan Indonesia.\n'
          'Format: 1.Ringkasan 2.Komponen 3.Harga 4.Analisis.'
        ),
      );

      // Konversi history ke format Content (hanya ambil beberapa pesan terakhir untuk efisiensi)
      final limitedHistory = history != null && history.length > 6 
          ? history.sublist(history.length - 6) 
          : (history ?? []);

      final contentHistory = limitedHistory.where((msg) => msg['text'] != prompt).map((msg) {
        if (msg['role'] == 'user') {
          return Content.text(msg['text'] ?? '');
        } else {
          return Content.model([TextPart(msg['text'] ?? '')]);
        }
      }).toList();

      final chat = model.startChat(history: contentHistory);
      final response = await chat.sendMessage(Content.text(prompt));
      
      final result = response.text ?? 'Maaf, saya tidak bisa memberikan jawaban saat ini.';
      return _addSuggestions(result);
    } catch (e) {
      print('Gemini Error: $e');
      if (e.toString().contains('403')) {
        return '🤖 **ARIA (Error 403):** Akses ditolak oleh server Gemini.\n\n'
               '**Kemungkinan penyebab:**\n'
               '1. API Key Anda memiliki pembatasan (Restriction) di Google Cloud Console, '
               'tapi SHA-1 fingerprint aplikasi build ini belum didaftarkan.\n'
               '2. Akun Google Anda berada di wilayah yang belum didukung untuk model ini.\n'
               '3. API Key sudah tidak aktif atau salah.';
      }
      return '🤖 **ARIA:** Terjadi kesalahan saat menghubungi server AI. ($e)';
    }
  }

  String _addSuggestions(String text) {
    if (text.contains('Tanyakan ARIA')) return text;
    return '$text\n\n---\n**Tanyakan ARIA selanjutnya:**\n'
        '• "Apa komponen terbaik budget ini?"\n'
        '• "Cek bottleneck build ini?"';
  }
}
