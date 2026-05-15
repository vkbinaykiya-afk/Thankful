import 'package:supabase_flutter/supabase_flutter.dart';

/// Updates [streaks] after a journal entry is saved.
class StreakService {
  const StreakService();

  static DateTime _localDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime? _parseLastEntryDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final parsed = DateTime.parse(raw);
      return _localDateOnly(parsed.toLocal());
    }
    if (raw is DateTime) return _localDateOnly(raw.toLocal());
    return null;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static String _dateOnlyIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Applies streak rules after a new entry; no-op if user already journaled today.
  Future<void> updateStreakAfterEntry(String userId) async {
    final today = _localDateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    Map<String, dynamic>? row;
    try {
      final data = await Supabase.instance.client
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data != null) {
        row = Map<String, dynamic>.from(data as Map);
      }
    } catch (_) {
      row = null;
    }

    final lastEntryDate = row != null
        ? _parseLastEntryDate(row['last_entry_date'])
        : null;

    if (lastEntryDate != null && lastEntryDate == today) {
      return;
    }

    final previousCurrent =
        row != null ? _asInt(row['current_streak']) : 0;
    final previousLongest =
        row != null ? _asInt(row['longest_streak']) : 0;

    final newCurrent = lastEntryDate == yesterday
        ? previousCurrent + 1
        : 1;
    final newLongest = newCurrent > previousLongest
        ? newCurrent
        : previousLongest;

    final payload = <String, dynamic>{
      'user_id': userId,
      'current_streak': newCurrent,
      'longest_streak': newLongest,
      'last_entry_date': _dateOnlyIso(today),
    };

    if (row == null) {
      await Supabase.instance.client.from('streaks').insert(payload);
    } else {
      await Supabase.instance.client
          .from('streaks')
          .update({
            'current_streak': newCurrent,
            'longest_streak': newLongest,
            'last_entry_date': payload['last_entry_date'],
          })
          .eq('user_id', userId);
    }
  }
}
