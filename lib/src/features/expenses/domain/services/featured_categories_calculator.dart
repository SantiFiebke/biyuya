import 'package:biyuya/src/core/constants/app_constants.dart';
import 'package:biyuya/src/features/expenses/domain/entities/expense.dart';

/// Pure helper: returns the [limit] most frequent category ids among the
/// expenses whose `date` falls inside the last 7 days relative to [now].
///
/// Window is inclusive: `now - 7 days <= date <= now`.
/// Ordering: frequency DESC, then most recent expense date DESC, then id ASC.
/// No I/O: takes the already-loaded expense list.
List<int> topCategoryIdsLastWeek(
  List<Expense> expenses,
  DateTime now, {
  int limit = kFeaturedCategoryCount,
}) {
  final windowStart = now.subtract(const Duration(days: 7));
  final counts = <int, int>{};
  final latestDate = <int, DateTime>{};

  for (final expense in expenses) {
    final date = expense.date;
    // Expense.categoryId is non-nullable in this codebase, so no null filter.
    if (date.isBefore(windowStart) || date.isAfter(now)) {
      continue;
    }
    final id = expense.categoryId;
    counts[id] = (counts[id] ?? 0) + 1;
    final previous = latestDate[id];
    if (previous == null || date.isAfter(previous)) {
      latestDate[id] = date;
    }
  }

  final ids = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) {
        return byCount;
      }
      final byDate = latestDate[b]!.compareTo(latestDate[a]!);
      if (byDate != 0) {
        return byDate;
      }
      return a.compareTo(b);
    });

  return ids.take(limit).toList();
}
