import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/auth_provider.dart';
import '../converter/converter_page.dart';
import '../builder/saved_builds_page.dart';
import '../../core/services/biometric_service.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imagePath;
  Uint8List? _webImageBytes;
  Map<String, Object?>? _user;
  bool _loading = false;
  final _biometricService = BiometricService();
  bool _biometricEnabled = false;
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    setState(() => _loading = true);
    final user = await DatabaseService.instance.getUserById(auth.userId!);
    if (!mounted) return;
    setState(() {
      _user = user;
      _imagePath = user?['profile_image']?.toString();
      _biometricEnabled = (user?['biometric_enabled'] as int? ?? 0) == 1;
      _usernameController.text = user?['username']?.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    
    setState(() => _loading = true);
    
    // Simpan username
    await DatabaseService.instance.updateUsername(auth.userId!, _usernameController.text);
    
    // Simpan foto profil
    if (_imagePath != null) {
      await DatabaseService.instance.updateProfileImage(auth.userId!, _imagePath!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil disimpan!')),
    );
    _loadUser();
  }

  Future<void> _registerBiometric() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    final can = await _biometricService.canCheckBiometrics();
    if (!can) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometrik tidak tersedia di perangkat ini.')),
    );
      return;
    }

    final ok = await _biometricService.authenticate();
    if (ok) {
      await DatabaseService.instance.updateBiometricStatus(auth.userId!, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrik berhasil didaftarkan!')),
      );
      _loadUser();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() => _webImageBytes = bytes);
    } else {
      setState(() => _imagePath = file.path);
    }

    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      await DatabaseService.instance.updateProfileImage(auth.userId!, file.path);
      if (!mounted) return;
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surface,
                backgroundImage: _buildProfileImage(),
                child: _buildProfileImage() == null ? const Icon(Icons.camera_alt) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          Text('Email: ${_user?['email'] ?? '-'}'),
          const SizedBox(height: 12),
          Text('Biometrik: ${_biometricEnabled ? 'Aktif' : 'Belum Aktif'}'),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Simpan Profil',
            onPressed: _saveProfile,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Daftar Biometrik',
            onPressed: _registerBiometric,
            isPrimary: false,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Buka Konverter',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConverterPage()),
            ),
            isPrimary: false,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Lihat Build Saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedBuildsPage()),
            ),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  ImageProvider? _buildProfileImage() {
    if (kIsWeb) {
      if (_webImageBytes == null) return null;
      return MemoryImage(_webImageBytes!);
    }
    if (_imagePath == null || _imagePath!.isEmpty) return null;
    return FileImage(File(_imagePath!));
  }
}
