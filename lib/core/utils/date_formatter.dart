import 'package:intl/intl.dart';

/// Utilities for standard UTC handling and local display formatting.
/// Enforces: "All timestamps are stored in UTC and displayed in the user's configured timezone."
abstract final class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, y • h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, y');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _relativeDayFormat = DateFormat('EEEE, MMM d');

  /// Formats UTC [dateTime] to the user's local timezone.
  static String formatToLocal(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return _dateTimeFormat.format(local);
  }

  /// Formats date portion only in local time.
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return _dateFormat.format(local);
  }

  /// Formats time portion only in local time.
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    return _timeFormat.format(local);
  }

  /// Returns friendly relative string: "Today at 2:30 PM", "Tomorrow at 10:00 AM", or "Oct 12 • 4:00 PM"
  static String formatRelative(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();

    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final isTomorrow = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day + 1;

    if (isToday) {
      return 'Today at ${_timeFormat.format(local)}';
    } else if (isTomorrow) {
      return 'Tomorrow at ${_timeFormat.format(local)}';
    } else {
      return '${_dateFormat.format(local)} • ${_timeFormat.format(local)}';
    }
  }

  /// Formats day header for Calendar / Queue grouping.
  static String formatDayHeader(DateTime dateTime) {
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today (${_dateFormat.format(local)})';
    }
    return _relativeDayFormat.format(local);
  }
}
