import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/errors/app_error.dart';
import 'package:no5ocial/core/theme/app_colors.dart';

/// Global application error handling coordinator.
/// Differentiates between production and development error presentation,
/// ensuring raw server exceptions, stack traces, and secrets are NEVER leaked
/// to normal users in production, while retaining rich diagnostics for developers.
class AppErrorHandler {
  /// Initialize global Flutter & platform error hooks.
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('AppErrorHandler [FlutterError]: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('AppErrorHandler [PlatformDispatcher]: $error\n$stack');
      return true; // Prevents crash
    };
  }

  /// Display a styled error sheet or dialog tailored to the active environment (dev vs prod).
  static Future<void> showError(
    BuildContext context,
    dynamic error, {
    StackTrace? stackTrace,
    String? fallbackTitle,
    VoidCallback? onRetry,
  }) async {
    final appException = AppException.from(
      error,
      stackTrace: stackTrace,
      fallbackTitle: fallbackTitle,
    );

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppErrorSheet(
        exception: appException,
        isDev: EnvConfig.isDev,
        onRetry: onRetry,
      ),
    );
  }
}

class _AppErrorSheet extends StatefulWidget {
  final AppException exception;
  final bool isDev;
  final VoidCallback? onRetry;

  const _AppErrorSheet({
    required this.exception,
    required this.isDev,
    this.onRetry,
  });

  @override
  State<_AppErrorSheet> createState() => _AppErrorSheetState();
}

class _AppErrorSheetState extends State<_AppErrorSheet> {
  bool _showDevDetails = false;
  bool _copied = false;

  void _copyToClipboard() {
    final report = '''
[no5ocial Error Report]
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Error Code Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exception.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            widget.exception.code,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (widget.isDev) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEV DIAGNOSTICS ACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User-friendly production message
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.exception.userMessage,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),

          // Development-only technical details
          if (widget.isDev && widget.exception.devDetails != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showDevDetails = !_showDevDetails),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showDevDetails ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showDevDetails ? 'Hide Developer Stack & Details' : 'Show Developer Technical Details',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showDevDetails) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Raw Error Output:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          TextButton.icon(
                            onPressed: _copyToClipboard,
                            icon: Icon(_copied ? Icons.check : Icons.copy, size: 12, color: AppColors.accent),
                            label: Text(
                              _copied ? 'Copied!' : 'Copy',
                              style: const TextStyle(fontSize: 11, color: AppColors.accent),
                            ),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exception.devDetails!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (widget.exception.stackTrace != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.exception.stackTrace.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onRetry!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
