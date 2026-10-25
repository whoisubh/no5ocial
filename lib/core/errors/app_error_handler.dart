import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/errors/app_error.dart';
import 'package:no5ocial/core/theme/app_colors.dart';

/// Central global application error handler and notification coordinator.
///
/// Guarantees:
/// 1. Uniform, premium toast-style presentation across the entire application.
/// 2. Structured 5-digit numeric Error IDs (e.g. 12003 for Auth Failed) for rapid debugging.
/// 3. Clear differentiation between Development (rich diagnostics) and Production (sanitized guidance).
/// 4. Zero sensitive token, stack trace, or secret leakage in production flavors.
class AppErrorHandler {
  /// Global ScaffoldMessengerKey allowing toast notifications from any layer.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global NavigatorKey for application-wide overlays and navigation contexts.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize global Flutter & platform error hooks.
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      final exception = AppException.from(
        details.exception,
        stackTrace: details.stack,
        fallbackTitle: 'Framework Error',
      );
      debugPrint('AppErrorHandler [FlutterError ${exception.errorId}]: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final exception = AppException.from(
        error,
        stackTrace: stack,
        fallbackTitle: 'Platform Dispatcher Error',
      );
      debugPrint('AppErrorHandler [PlatformDispatcher ${exception.errorId}]: $error\n$stack');
      return true; // Prevents app crash
    };
  }

  /// Displays a consistent, toast-like error notification with an immutable numeric Error ID.
  ///
  /// In **Development Flavor**: displays rich exception details and a 1-tap "Details" button.
  /// In **Production Flavor**: displays sanitized, friendly guidance with the Error ID for support.
  static void showError(
    BuildContext? context,
    dynamic error, {
    StackTrace? stackTrace,
    String? fallbackTitle,
    int? overrideErrorId,
    VoidCallback? onRetry,
  }) {
    final appException = AppException.from(
      error,
      stackTrace: stackTrace,
      fallbackTitle: fallbackTitle,
      overrideErrorId: overrideErrorId,
    );

    final isDev = EnvConfig.isDev || kDebugMode;
    final message = appException.getEffectiveMessage(isDev: isDev);

    showAppToast(
      context: context,
      title: appException.title,
      message: message,
      errorId: appException.errorId,
      type: ToastType.error,
      exception: appException,
      onRetry: onRetry,
    );
  }

  /// Displays a success toast with the unified HUD styling.
  static void showSuccess(BuildContext? context, String message, {String? title}) {
    showAppToast(
      context: context,
      title: title ?? 'Success',
      message: message,
      type: ToastType.success,
    );
  }

  /// Displays an informational toast with the unified HUD styling.
  static void showInfo(BuildContext? context, String message, {String? title}) {
    showAppToast(
      context: context,
      title: title ?? 'Notice',
      message: message,
      type: ToastType.info,
    );
  }

  /// Primary builder for the floating toast-like notification across the application.
  static void showAppToast({
    BuildContext? context,
    required String title,
    required String message,
    int? errorId,
    ToastType type = ToastType.error,
    AppException? exception,
    VoidCallback? onRetry,
  }) {
    final messenger = context != null
        ? ScaffoldMessenger.maybeOf(context) ?? scaffoldMessengerKey.currentState
        : scaffoldMessengerKey.currentState;

    if (messenger == null) {
      debugPrint('AppErrorHandler Toast [${type.name.toUpperCase()} ${errorId ?? ""}] $title: $message');
      return;
    }

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        duration: Duration(seconds: type == ToastType.error ? 5 : 4),
        content: _UnifiedToastCard(
          title: title,
          message: message,
          errorId: errorId,
          type: type,
          exception: exception,
          onRetry: onRetry,
          onDismiss: () => messenger.hideCurrentSnackBar(),
          onShowDetails: (ctx, ex) => _showDiagnosticsModal(ctx, ex),
        ),
      ),
    );
  }

  /// Developer Diagnostics Sheet shown when tapping "Details" in Development mode.
  static void _showDiagnosticsModal(BuildContext context, AppException exception) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DiagnosticsSheet(exception: exception),
    );
  }
}

enum ToastType { error, success, info }

/// Universal Toast-like HUD Card
class _UnifiedToastCard extends StatelessWidget {
  final String title;
  final String message;
  final int? errorId;
  final ToastType type;
  final AppException? exception;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;
  final void Function(BuildContext, AppException)? onShowDetails;

  const _UnifiedToastCard({
    required this.title,
    required this.message,
    this.errorId,
    required this.type,
    this.exception,
    this.onRetry,
    required this.onDismiss,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color accentColor;
    Color iconBg;
    IconData iconData;

    switch (type) {
      case ToastType.error:
        accentColor = AppColors.error;
        iconBg = const Color(0xFFFEE2E2);
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.success:
        accentColor = const Color(0xFF059669);
        iconBg = const Color(0xFFECFDF5);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case ToastType.info:
        accentColor = AppColors.accent;
        iconBg = AppColors.accent.withValues(alpha: 0.12);
        iconData = Icons.info_outline_rounded;
        break;
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isDev = EnvConfig.isDev || kDebugMode;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.7 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Pill
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),

          // Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (errorId != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$errorId',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorId != null) ...[
                Tooltip(
                  message: 'Copy Error ID',
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'Error ID: $errorId ($title)'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied Error ID $errorId to clipboard'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
              if (isDev && exception != null && onShowDetails != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Developer Details',
                  child: InkWell(
                    onTap: () => onShowDetails!(context, exception!),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.code_rounded, size: 15, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    onDismiss();
                    onRetry!();
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded, size: 15, color: accentColor),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Developer Diagnostics Modal Sheet
class _DiagnosticsSheet extends StatefulWidget {
  final AppException exception;

  const _DiagnosticsSheet({required this.exception});

  @override
  State<_DiagnosticsSheet> createState() => _DiagnosticsSheetState();
}

class _DiagnosticsSheetState extends State<_DiagnosticsSheet> {
  bool _copied = false;

  void _copyDiagnostics() {
    final report = '''
[no5ocial Error Diagnostics]
Error ID: ${widget.exception.errorId}
Code: ${widget.exception.code}
Title: ${widget.exception.title}
Message: ${widget.exception.userMessage}
Timestamp: ${widget.exception.timestamp.toIso8601String()}
Dev Details: ${widget.exception.devDetails ?? 'None'}
Stack Trace:
${widget.exception.stackTrace ?? 'None'}
''';
    Clipboard.setData(ClipboardData(text: report));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bug_report_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical Diagnostics [${widget.exception.errorId}]',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    Text(
                      widget.exception.title,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raw Exception:',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.exception.devDetails ?? widget.exception.userMessage,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontFamily: 'monospace'),
                  ),
                  if (widget.exception.stackTrace != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Stack Trace:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exception.stackTrace.toString(),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _copyDiagnostics,
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
            label: Text(_copied ? 'Copied Diagnostics!' : 'Copy Full Diagnostics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
