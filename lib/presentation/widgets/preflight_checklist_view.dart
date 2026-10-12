import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/validators/preflight_validator.dart';

class PreflightChecklistView extends StatelessWidget {
  final PreflightResult result;

  const PreflightChecklistView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final charRatio = (result.characterCount / result.maxCharacters).clamp(
      0.0,
      1.0,
    );
    final isCharOverflow = result.characterCount > result.maxCharacters;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & character counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    result.isValid
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: result.isValid ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.isValid
                        ? 'Preflight Passed'
                        : 'Action Required (${result.blockers.length} Blocker)',
                    style: AppTypography.titleMedium.copyWith(
                      color: result.isValid
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${result.characterCount} / ${result.maxCharacters} chars',
                style: AppTypography.code.copyWith(
                  color: isCharOverflow
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: isCharOverflow
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: charRatio,
              minHeight: 4,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCharOverflow
                    ? AppColors.error
                    : charRatio > 0.9
                    ? AppColors.warning
                    : AppColors.accent,
              ),
            ),
          ),
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 6),
            ...result.issues.map((issue) => _buildIssueRow(issue)),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueRow(ValidationIssue issue) {
    Color color;
    IconData icon;
    switch (issue.severity) {
      case ValidationSeverity.blocker:
        color = AppColors.error;
        icon = Icons.cancel_outlined;
      case ValidationSeverity.warning:
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
      case ValidationSeverity.info:
        color = AppColors.neutral;
        icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
                if (issue.remedy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Remedy: ${issue.remedy!}',
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
