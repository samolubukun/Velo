import 'package:intl/intl.dart';

class NumberFormatter {
  static final _currencyFormat = NumberFormat('#,##0.00');
  static final _integerFormat = NumberFormat('#,##0');

  /// Formats a double value with thousands separators and 2 decimal places (e.g. 1,000.00)
  static String formatDouble(double val) {
    return _currencyFormat.format(val);
  }

  /// Formats a double value with thousands separators but no decimal places (e.g. 1,000)
  static String formatInt(num val) {
    return _integerFormat.format(val);
  }

  /// Helper to safely parse user entered values (removes commas first)
  static double parseAmount(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
