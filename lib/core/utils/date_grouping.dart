/// Single source of truth for the Today / Yesterday / This Week / This Month /
/// Older timeline buckets used by Transactions and Dashboard recents.
enum DateBucket { today, yesterday, thisWeek, thisMonth, older }

extension DateBucketLabel on DateBucket {
  String get label => switch (this) {
        DateBucket.today => 'Today',
        DateBucket.yesterday => 'Yesterday',
        DateBucket.thisWeek => 'This Week',
        DateBucket.thisMonth => 'This Month',
        DateBucket.older => 'Older',
      };
}

class DateGrouping {
  DateGrouping._();

  static DateBucket bucketFor(DateTime d, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;

    if (diff <= 0) return DateBucket.today;
    if (diff == 1) return DateBucket.yesterday;
    if (diff < 7) return DateBucket.thisWeek;
    if (d.year == ref.year && d.month == ref.month) return DateBucket.thisMonth;
    return DateBucket.older;
  }

  /// Groups items by bucket, preserving input order within each bucket and
  /// returning buckets in chronological display order.
  static Map<DateBucket, List<T>> group<T>(
    List<T> items,
    DateTime Function(T) dateOf, {
    DateTime? now,
  }) {
    final map = <DateBucket, List<T>>{};
    for (final item in items) {
      final b = bucketFor(dateOf(item), now: now);
      (map[b] ??= []).add(item);
    }
    return {
      for (final b in DateBucket.values)
        if (map[b] != null) b: map[b]!,
    };
  }
}
