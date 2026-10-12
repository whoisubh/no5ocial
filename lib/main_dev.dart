import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/main.dart' as app;

/// Development Entrypoint
/// Usage: flutter run -t lib/main_dev.dart
void main() async {
  await app.bootstrap(flavor: AppFlavor.dev);
}
