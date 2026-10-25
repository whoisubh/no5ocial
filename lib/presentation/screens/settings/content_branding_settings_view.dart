import 'package:flutter/material.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/domain/enums/platform_type.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/platform_logo.dart';

class ContentBrandingSettingsView extends StatefulWidget {
  final AppState appState;

  const ContentBrandingSettingsView({super.key, required this.appState});

  @override
  State<ContentBrandingSettingsView> createState() => _ContentBrandingSettingsViewState();
}

class _ContentBrandingSettingsViewState extends State<ContentBrandingSettingsView> {
  late bool _titleBrandingEnabled;
  late TextEditingController _suffixController;
  late bool _signatureEnabled;
  late TextEditingController _signatureController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleBrandingEnabled = widget.appState.titleBrandingEnabled;
    _suffixController = TextEditingController(text: widget.appState.titleBrandingSuffix);
    _signatureEnabled = widget.appState.descriptionSignatureEnabled;
    _signatureController = TextEditingController(text: widget.appState.descriptionSignature);
  }

  @override
  void dispose() {
    _suffixController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    await widget.appState.updateTitleBranding(
      enabled: _titleBrandingEnabled,
      suffix: _suffixController.text,
    );

    await widget.appState.updateDescriptionSignature(
      enabled: _signatureEnabled,
      signature: _signatureController.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content branding and signatures saved successfully.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.surfaceOf(context);
    final innerBg = isDark ? const Color(0xFF131A29) : const Color(0xFFF8FAFC);
    final borderColor = AppColors.borderOf(context);
    final textColor = AppColors.textOf(context);

    final previewChannel = widget.appState.accounts
            .where((a) => a.platform == PlatformType.youtube)
            .firstOrNull
            ?.displayName ??
        'YourChannel';
    final previewBrand = widget.appState.brands.firstOrNull?.name ?? 'YourBrand';

    final effectiveSuffix = _titleBrandingEnabled
        ? _suffixController.text
            .replaceAll('{channel_name}', previewChannel)
            .replaceAll('{brand_name}', previewBrand)
        : '';

    const sampleTitle = '10 Editing Secrets Every Creator Must Know';
    final fullPreview = '$sampleTitle$effectiveSuffix';
    final titleLength = fullPreview.length;
    final isOverflow = titleLength > 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.branding_watermark_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Title & Description Branding',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure channel suffixes and description footers once. Length limits are guarded automatically.',
                      style: AppTypography.bodySecondary.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. YouTube Title Suffix Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        PlatformLogo(platform: PlatformType.youtube, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'YouTube Title Branding',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _titleBrandingEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) => setState(() => _titleBrandingEnabled = val),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically appends your brand suffix to YouTube video titles (e.g. "[Title] | [Channel]").',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
                if (_titleBrandingEnabled) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _suffixController,
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Suffix Template',
                      hintText: ' | {channel_name}',
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      helperText: 'Variables: {channel_name}, {brand_name}',
                      helperStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: cardBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip(' | {channel_name}', cardBg, borderColor),
                      _buildPresetChip(' | {brand_name}', cardBg, borderColor),
                      _buildPresetChip(' - {channel_name}', cardBg, borderColor),
                      _buildPresetChip(' • {channel_name}', cardBg, borderColor),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverflow ? AppColors.errorBg : (isDark ? const Color(0xFF0F1523) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverflow ? AppColors.errorBorder : borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sample Title Preview:',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isOverflow ? AppColors.error : AppColors.accent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverflow
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$titleLength / 100 chars',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOverflow ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fullPreview,
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverflow ? AppColors.error : textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOverflow) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Warning: Exceeds YouTube 100 character limit by ${titleLength - 100} chars. Titles over 100 characters will be rejected.',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Description Signature Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          'Description Signature / Footer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _signatureEnabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: (val) => setState(() => _signatureEnabled = val),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically appends social links or signatures to post descriptions.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
                if (_signatureEnabled) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _signatureController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 12.5, color: textColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Signature Template',
                      hintText: '---\nFollow us: {website}\nSubscribe for weekly updates!',
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      helperText: 'Variables: {brand_name}, {website}',
                      helperStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: cardBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Branding Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String template, Color cardBg, Color borderColor) {
    final isSelected = _suffixController.text == template;
    return InkWell(
      onTap: () {
        setState(() {
          _suffixController.text = template;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : borderColor,
          ),
        ),
        child: Text(
          template,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
