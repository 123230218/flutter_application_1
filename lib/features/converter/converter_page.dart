import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/currency_converter.dart';
import '../../core/utils/time_zone_converter.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController(text: '1');
  String _from = 'USD';
  String _to = 'IDR';
  Map<String, double> _rates = {};
  DateTime? _lastUpdated;
  bool _loadingRates = false;
  String? _ratesError;
  DateTime _time = DateTime.now();
  String _baseZone = 'WIB';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() {
      _loadingRates = true;
      _ratesError = null;
    });
    try {
      final rates = await ApiService.instance.fetchExchangeRates();
      final updated = await ApiService.instance.getExchangeRateLastUpdated();
      
      // Filter currencies we care about or show all if needed
      // For this UI, we'll keep it focused on popular ones but allow all from API
      final allowed = {'USD', 'IDR', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'MYR', 'CNY'};
      final filteredRates = {
        for (final entry in rates.entries)
          if (allowed.contains(entry.key)) entry.key: entry.value,
      };

      if (!mounted) return;
      setState(() {
        _rates = filteredRates.isEmpty ? rates : filteredRates;
        _lastUpdated = updated;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ratesError = 'Gagal memuat kurs terbaru.');
    } finally {
      if (mounted) {
        setState(() => _loadingRates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final result = _rates.isEmpty
        ? 0.0
        : CurrencyConverter.convert(amount: amount, from: _from, to: _to, rates: _rates);
    
    final currencyKeys = _rates.isEmpty
      ? ['USD', 'IDR', 'EUR', 'JPY', 'GBP']
      : _rates.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Konverter',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadRates,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Mata Uang'),
            Tab(text: 'Waktu Dunia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(amount, result, currencyKeys),
          _buildTimeTab(),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab(double amount, double result, List<String> currencyKeys) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Result Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surface, Color(0xFF252A41)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Hasil Konversi',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(
                  CurrencyConverter.format(result, _to),
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_lastUpdated != null)
                Text(
                  'Kurs: ${DateFormat('dd MMM yyyy, HH:mm').format(_lastUpdated!)}',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Input Section
        Text(
          'Nominal',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: 'Masukkan jumlah...',
            hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.secondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.surface.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondary),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // Selectors
        Row(
          children: [
            Expanded(child: _buildCurrencyDropdown('Dari', _from, currencyKeys, (v) => setState(() => _from = v!))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  final temp = _from;
                  _from = _to;
                  _to = temp;
                }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.swap_horiz, color: AppColors.secondary),
                ),
              ),
            ),
            Expanded(child: _buildCurrencyDropdown('Ke', _to, currencyKeys, (v) => setState(() => _to = v!))),
          ],
        ),
        
        if (_loadingRates) 
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text('Memperbarui kurs...', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        
        if (_ratesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _ratesError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeTab() {
    final zoneTimes = TimeZoneConverter.convert(_time, _baseZone);
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Base Time Picker
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Waktu Lokal',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                ),
                subtitle: Text(
                  TimeZoneConverter.format(_time, is24Hour: true),
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled, color: AppColors.secondary),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_time),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.secondary,
                            onPrimary: Colors.white,
                            surface: AppColors.surface,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    setState(() {
                      _time = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                    });
                  }
                },
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildZoneDropdown(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'Zona Waktu Dunia',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...zoneTimes.entries.where((e) => e.key != _baseZone).map((entry) {
          final time24 = TimeZoneConverter.format(entry.value, is24Hour: true);
          final time12 = DateFormat('hh:mm a').format(entry.value);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getCityName(entry.key),
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time24,
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time12,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildZoneDropdown() {
    final zones = ['WIB', 'WITA', 'WIT', 'London', 'New York', 'Tokyo'];
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _baseZone,
        dropdownColor: AppColors.surface,
        decoration: InputDecoration(
          labelText: 'Zona Asal',
          labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        items: zones.map((z) => DropdownMenuItem(
          value: z,
          child: Text(z, style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        )).toList(),
        onChanged: (v) => setState(() => _baseZone = v ?? 'WIB'),
      ),
    );
  }

  String _getCityName(String zone) {
    switch (zone) {
      case 'WIB': return 'Jakarta, Indonesia';
      case 'WITA': return 'Makassar, Indonesia';
      case 'WIT': return 'Jayapura, Indonesia';
      case 'London': return 'United Kingdom';
      case 'New York': return 'USA';
      case 'Tokyo': return 'Japan';
      default: return '';
    }
  }
}
