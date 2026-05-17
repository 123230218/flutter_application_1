import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/auth_provider.dart';
import '../auth/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isAuthenticating = false;
  String? _error;
  bool _biometricReady = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    BiometricService.instance.stopAuthentication();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final lastEmail = await auth.getLastEmail();
      if (lastEmail != null && mounted) {
        final user = await DatabaseService.instance.getUserByEmail(lastEmail);
        if (mounted) {
          setState(() {
            _biometricReady = (user?['biometric_enabled'] as int? ?? 0) == 1;
          });
        }
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();

    // Validasi: hanya email @gmail.com yang diizinkan
    if (!email.toLowerCase().endsWith('@gmail.com')) {
      setState(() => _error = 'Email harus menggunakan @gmail.com');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.login(
      email,
      _passwordController.text.trim(),
    );

    setState(() {
      _loading = false;
      _error = error;
    });

    if (error == null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _handleBiometric() async {
    if (_isAuthenticating) return;

    final auth = context.read<AuthProvider>();
    final lastEmail = await auth.getLastEmail();
    if (lastEmail == null) {
      setState(() => _error = 'Login manual dulu sebelum pakai biometrik.');
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final can = await BiometricService.instance.canCheckBiometrics();
      if (!can) {
        setState(() {
          _error = 'Biometrik tidak tersedia.';
          _isAuthenticating = false;
        });
        return;
      }

      final ok = await BiometricService.instance.authenticate();
      if (!ok) {
        setState(() {
          _error = 'Autentikasi biometrik gagal.';
          _isAuthenticating = false;
        });
        return;
      }

      final error = await auth.loginWithBiometric(lastEmail);
      if (error != null) {
        setState(() {
          _error = error;
          _isAuthenticating = false;
        });
      } else if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 48),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 180,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Selamat datang di PC Builder Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'contoh@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(label: 'Masuk', onPressed: _handleLogin),
            _isAuthenticating
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'Login dengan Biometrik',
                    onPressed: _biometricReady ? _handleBiometric : () {},
                    isPrimary: false,
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: const Text('Belum punya akun? Daftar'),
            )
          ],
        ),
      ),
    );
  }
}
