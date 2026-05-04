import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'core/services/database_service.dart';
import 'core/utils/notification_helper.dart';
import 'core/utils/session_manager.dart';
import 'features/ai_chat/ai_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/builder/build_provider.dart';
import 'features/home/home_provider.dart';
import 'features/map/map_provider.dart';
import 'features/parts/parts_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  tz.initializeTimeZones();
  await DatabaseService.instance.initialize();
  await NotificationHelper.initialize();
  await Hive.openBox('session_box');
  await Hive.openBox('auth_cache');

  final sessionManager = SessionManager();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: sessionManager),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(sessionManager: sessionManager),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => PartsProvider()),
        ChangeNotifierProvider(create: (_) => BuildProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const PcBuilderApp(),
    ),
  );
}
