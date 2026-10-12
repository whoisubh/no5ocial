import 'package:flutter/widgets.dart';
import 'package:no5ocial/l10n/app_localizations.dart';

/// Convenient extension on BuildContext to quickly access typed localizations.
/// Example: `context.l10n.navQueue`
extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
