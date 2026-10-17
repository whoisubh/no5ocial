// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

Map<String, String>? getWebStoredChannel() {
  try {
    final raw = html.window.localStorage['no5ocial_linked_channel'];
    if (raw != null && raw.isNotEmpty) {
      html.window.localStorage.remove('no5ocial_linked_channel');
      final data = jsonDecode(raw);
      if (data is Map) {
        return {
          'connected': data['platform']?.toString() ?? 'linkedin',
          'channelId': data['id']?.toString() ?? '',
          'channelTitle': data['title']?.toString() ?? '',
          'channelHandle': data['handle']?.toString() ?? '',
          'brandId': data['brandId']?.toString() ?? '',
          'accountType': data['accountType']?.toString() ?? '',
          'accessToken': data['accessToken']?.toString() ?? '',
        };
      }
    }
  } catch (_) {}
  return null;
}

void clearUrlQuery() {
  try {
    final path = html.window.location.pathname ?? '/accounts';
    html.window.history.replaceState(null, '', path);
  } catch (_) {}
}
