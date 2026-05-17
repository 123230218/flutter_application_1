import 'package:intl/intl.dart';

class CurrencyConverter {
  static double convert({
    required double amount,
    required String from,
    required String to,
    required Map<String, double> rates,
  }) {
    if (from == to) {
      return amount;
    }
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  static String format(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String _getSymbol(String code) {
    switch (code) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$ ';
      case 'JPY':
        return '¥ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      default:
        return '$code ';
    }
  }
}
