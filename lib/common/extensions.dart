// lib/common/extensions.dart
import 'package:intl/intl.dart';

// Helper for formatting numbers with commas and currency
extension NumExtension on num {
  String toLocaleString() {
    // Format as Indian Rupee with comma separation
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(this);
  }
}
