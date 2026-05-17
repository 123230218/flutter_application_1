import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _kirimChat({String? customPrompt}) async {
    final text = customPrompt ?? _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add({'role': 'user', 'text': text});
      if (customPrompt == null) _controller.clear();
    });

    try {
      if (ApiConstants.geminiApiKey.isEmpty || ApiConstants.geminiApiKey.contains('API_KEY')) {
        setState(() {
          _messages.add({'role': 'bot', 'text': 'Silakan isi API Key Gemini di ApiConstants.dart terlebih dahulu.'});
        });
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiConstants.geminiApiKey,
      );

      final content = [Content.text(text)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.add({'role': 'bot', 'text': response.text ?? 'Gagal mendapatkan respon.'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            tooltip: 'Minta Rekomendasi',
            onPressed: () => _kirimChat(customPrompt: 'Berikan rekomendasi rakitan PC gaming dengan budget 10 juta rupiah.'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dapatkan API Key gratis di aistudio.google.com',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Tanya spesifikasi PC...',
                    ),
                    onSubmitted: (_) => _kirimChat(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _kirimChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
