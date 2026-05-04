import 'package:flutter/material.dart';

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
      final allowed = {'USD', 'IDR', 'EUR', 'JPY', 'GBP'};
      final filteredRates = {
        for (final entry in rates.entries)
          if (allowed.contains(entry.key)) entry.key: entry.value,
      };
      if (!mounted) return;
      setState(() {
        _rates = filteredRates;
        _lastUpdated = updated;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ratesError = 'Gagal memuat kurs.');
    }
    if (mounted) {
      setState(() => _loadingRates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final result = _rates.isEmpty
        ? 0.0
        : CurrencyConverter.convert(amount: amount, from: _from, to: _to, rates: _rates);
    final zoneTimes = TimeZoneConverter.convert(_time, _baseZone);
    final currencyKeys = _rates.isEmpty
      ? ['USD', 'IDR', 'EUR', 'JPY', 'GBP']
      : _rates.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konverter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mata Uang'),
            Tab(text: 'Konversi Waktu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loadingRates) const LinearProgressIndicator(),
              if (_ratesError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_ratesError!, style: const TextStyle(color: AppColors.error)),
                ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _from,
                        items: currencyKeys
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      onChanged: (value) => setState(() => _from = value ?? 'USD'),
                      decoration: const InputDecoration(labelText: 'Dari'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => setState(() {
                      final temp = _from;
                      _from = _to;
                      _to = temp;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _to,
                        items: currencyKeys
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      onChanged: (value) => setState(() => _to = value ?? 'IDR'),
                      decoration: const InputDecoration(labelText: 'Ke'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Hasil: ${result.toStringAsFixed(2)} $_to'),
              const SizedBox(height: 8),
              Text('Kurs diperbarui: ${_lastUpdated ?? '-'}'),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Pilih waktu'),
                subtitle: Text(TimeZoneConverter.format(_time, is24Hour: true)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
                  if (picked != null) {
                    final now = DateTime.now();
                    setState(() {
                      _time = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _baseZone,
                items: const [
                  DropdownMenuItem(value: 'WIB', child: Text('WIB')),
                  DropdownMenuItem(value: 'WITA', child: Text('WITA')),
                  DropdownMenuItem(value: 'WIT', child: Text('WIT')),
                  DropdownMenuItem(value: 'London', child: Text('London')),
                  DropdownMenuItem(value: 'New York', child: Text('New York')),
                  DropdownMenuItem(value: 'Tokyo', child: Text('Tokyo')),
                ],
                onChanged: (value) => setState(() => _baseZone = value ?? 'WIB'),
                decoration: const InputDecoration(labelText: 'Zona asal'),
              ),
              const SizedBox(height: 16),
              ...zoneTimes.entries.map((entry) {
                final time24 = TimeZoneConverter.format(entry.value, is24Hour: true);
                final time12 = TimeZoneConverter.format(entry.value, is24Hour: false);
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('$time24 | $time12'),
                );
              }),
            ],
          )
        ],
      ),
    );
  }
}
