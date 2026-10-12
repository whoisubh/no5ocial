import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/main.dart' as app;

/// Production Entrypoint
/// Usage: flutter run -t lib/main_prod.dart
void main() async {
  await app.bootstrap(flavor: AppFlavor.prod);
}
