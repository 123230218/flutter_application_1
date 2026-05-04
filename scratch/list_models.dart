import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyBKAqdhBMaVUfbQQdSyTBHQYi2VOe3vw4c';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Available Models:');
      for (var model in data['models']) {
        print('- ${model['name']} (${model['supportedGenerationMethods']})');
      }
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
