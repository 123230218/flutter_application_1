import 'package:flutter/material.dart';

import '../features/ai_chat/ai_chat_page.dart';
import '../features/ai_chat/gemini_chat_screen.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/builder/build_page.dart';
import '../features/converter/converter_page.dart';
import '../features/feedback/feedback_page.dart';
import '../features/home/home_page.dart';
import '../features/map/store_map_page.dart';
import '../features/minigame/quiz_game_page.dart';
import '../features/parts/part_detail_page.dart';
import '../features/parts/parts_list_page.dart';
import '../features/parts/parts_search_page.dart';
import '../features/parts/compare_page.dart';
import '../features/profile/profile_page.dart';
import '../features/sensor/sensor_demo_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String builder = '/builder';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String feedback = '/feedback';
  static const String parts = '/parts';
  static const String partDetail = '/parts/detail';
  static const String partsSearch = '/parts/search';
  static const String aiChat = '/ai-chat';
  static const String geminiChat = '/ai-chat/gemini';
  static const String converter = '/converter';
  static const String quiz = '/quiz';
  static const String sensor = '/sensor';
  static const String compare = '/compare';

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      home: (context) => const HomePage(),
      builder: (context) => const BuildPage(),
      map: (context) => const StoreMapPage(),
      profile: (context) => const ProfilePage(),
      feedback: (context) => const FeedbackPage(),
      parts: (context) => const PartsListPage(),
      partsSearch: (context) => const PartsSearchPage(),
      partDetail: (context) => const PartDetailPage(),
      compare: (context) => const ComparePage(),
      aiChat: (context) => const AiChatPage(),
      geminiChat: (context) => const GeminiChatScreen(),
      converter: (context) => const ConverterPage(),
      quiz: (context) => const QuizGamePage(),
      sensor: (context) => const SensorDemoPage(),
    };
  }
}
