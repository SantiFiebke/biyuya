import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Syncs today's expense total to SharedPreferences so the native
/// Android widget can display "Gastado hoy: $X.XXX".
class WidgetDailyTotalSync {
  static const _keyTotal = 'widget_daily_total';
  static const _keyDate = 'widget_daily_date';

  /// Write today's total to SharedPreferences.
  static Future<void> syncTotal(double total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setDouble(_keyTotal, total);
      await prefs.setString(_keyDate, today);
    } on Exception catch (e) {
      _log.w('Failed to sync daily total to widget', error: e);
    }
  }

  /// Clear daily total (e.g., on logout).
  static Future<void> clearTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTotal);
      await prefs.remove(_keyDate);
    } on Exception catch (e) {
      _log.w('Failed to clear widget daily total', error: e);
    }
  }
}
