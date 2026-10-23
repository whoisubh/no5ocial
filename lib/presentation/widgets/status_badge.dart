import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';

/// Renders a status badge pairing color, icon, and text per DESIGN.md.
class StatusBadge extends StatelessWidget {
  final PublishJobStatus status;
  final bool isManual;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isManual = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    IconData icon;
    String label = status.label;

    if (isManual && status == PublishJobStatus.published) {
      bg = AppColors.neutralBg;
      border = AppColors.neutralBorder;
      fg = AppColors.textPrimary;
      icon = Icons.handshake_outlined;
      label = 'Manual Published';
    } else {
      switch (status) {
        case PublishJobStatus.draft:
          bg = AppColors.surfaceMuted;
          border = AppColors.border;
          fg = AppColors.textSecondary;
          icon = Icons.edit_note_outlined;
        case PublishJobStatus.needsApproval:
          bg = const Color(0xFFFEF3C7);
          border = const Color(0xFFFDE68A);
          fg = const Color(0xFFD97706);
          icon = Icons.pending_actions_outlined;
        case PublishJobStatus.scheduled:
          bg = AppColors.accentLight;
          border = const Color(0xFFC7D2FE);
          fg = AppColors.accent;
          icon = Icons.event_outlined;
        case PublishJobStatus.publishing:
          bg = const Color(0xFFEFF6FF);
          border = const Color(0xFFBFDBFE);
          fg = const Color(0xFF2563EB);
          icon = Icons.sync_outlined;
        case PublishJobStatus.published:
          bg = AppColors.successBg;
          border = AppColors.successBorder;
          fg = AppColors.success;
          icon = Icons.check_circle_outline;
        case PublishJobStatus.actionRequired:
          bg = AppColors.warningBg;
          border = AppColors.warningBorder;
          fg = AppColors.warning;
          icon = Icons.warning_amber_rounded;
        case PublishJobStatus.failed:
          bg = AppColors.errorBg;
          border = AppColors.errorBorder;
          fg = AppColors.error;
          icon = Icons.error_outline;
        case PublishJobStatus.cancelled:
          bg = AppColors.surfaceMuted;
          border = AppColors.border;
          fg = AppColors.textMuted;
          icon = Icons.cancel_outlined;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
