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
}
