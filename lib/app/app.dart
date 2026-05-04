import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_page.dart';
import '../features/builder/build_page.dart';
import '../features/feedback/feedback_page.dart';
import '../features/home/home_page.dart';
import '../features/map/store_map_page.dart';
import '../features/profile/profile_page.dart';
import '../widgets/bottom_nav.dart';
import 'routes.dart';

class PcBuilderApp extends StatelessWidget {
  const PcBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final titleTextTheme = GoogleFonts.rajdhaniTextTheme(baseTextTheme);

    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: titleTextTheme.headlineLarge,
        headlineMedium: titleTextTheme.headlineMedium,
        headlineSmall: titleTextTheme.headlineSmall,
        titleLarge: titleTextTheme.titleLarge,
        titleMedium: titleTextTheme.titleMedium,
        titleSmall: titleTextTheme.titleSmall,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );

    return MaterialApp(
      title: AppStrings.appName,
      theme: theme,
      routes: AppRoutes.buildRoutes(),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return auth.isLoggedIn ? const MainShell() : const LoginPage();
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _tabs = const [
    HomePage(),
    BuildPage(),
    StoreMapPage(),
    ProfilePage(),
    FeedbackPage(),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
