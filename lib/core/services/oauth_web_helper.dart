import 'oauth_web_helper_stub.dart'
    if (dart.library.html) 'oauth_web_helper_web.dart' as helper;

Map<String, String>? getStoredWebChannel() => helper.getWebStoredChannel();

void clearWebQuery() => helper.clearUrlQuery();
