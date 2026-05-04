import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyBKAqdhBMaVUfbQQdSyTBHQYi2VOe3vw4c';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Halo, ini test.'}
          ]
        }
      ]
    }),
  );
  print(response.statusCode);
  print(response.body);
}
