import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to generate and launch Google Calendar links for scheduled posts.
abstract final class CalendarExportHelper {
  /// Generates a direct Google Calendar template URL prefilled with event details.
  static String generateGoogleCalendarUrl({
    required String title,
    required DateTime scheduledAtUtc,
    String? details,
    String? location,
    Duration duration = const Duration(minutes: 30),
  }) {
    final utc = scheduledAtUtc.isUtc ? scheduledAtUtc : scheduledAtUtc.toUtc();
    final endUtc = utc.add(duration);

    final formatter = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final startStr = formatter.format(utc);
    final endStr = formatter.format(endUtc);

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '$startStr/$endStr',
      if (details != null && details.isNotEmpty) 'details': details,
      if (location != null && location.isNotEmpty) 'location': location,
    });

    return uri.toString();
  }

  /// Opens the event creation page directly in Google Calendar (app or browser).
  static Future<bool> openInGoogleCalendar({
    required String title,
    required DateTime scheduledAtUtc,
    String? details,
    String? location,
  }) async {
    final url = generateGoogleCalendarUrl(
      title: title,
      scheduledAtUtc: scheduledAtUtc,
      details: details,
      location: location,
    );
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
