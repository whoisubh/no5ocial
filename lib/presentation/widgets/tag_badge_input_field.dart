import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no5ocial/core/theme/app_colors.dart';

/// An interactive tag input field that divides tags into visual badges/chips
/// whenever the user enters a comma `,` or space ` `, or submits via Enter.
class TagBadgeInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final int maxCharacters;
  final int? recommendedMin;
  final int? recommendedMax;
  final String? platformNotice;
  final bool isHashtag;

  const TagBadgeInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Type tag and press comma or space...',
    this.maxCharacters = 500,
    this.recommendedMin,
    this.recommendedMax,
    this.platformNotice,
    this.isHashtag = false,
  });

  @override
  State<TagBadgeInputField> createState() => _TagBadgeInputFieldState();
}

class _TagBadgeInputFieldState extends State<TagBadgeInputField> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void _syncTagsToController(List<String> tags) {
    final joined = tags.join(', ');
    widget.controller.text = joined;
    widget.onChanged?.call(joined);
    setState(() {});
  }

  void _commitToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;

    final formatted = widget.isHashtag && !trimmed.startsWith('#')
        ? '#$trimmed'
        : trimmed;

    final currentTags = _parseTags(widget.controller.text);
    if (!currentTags.contains(formatted)) {
      currentTags.add(formatted);
      _syncTagsToController(currentTags);
    }
  }

  void _handleInputChanged(String val) {
    if (val.contains(',') || val.contains(' ')) {
      // Split on comma or space
      final tokens = val.split(RegExp(r'[, ]+'));
      for (int i = 0; i < tokens.length; i++) {
        final t = tokens[i];
        if (i < tokens.length - 1 || val.endsWith(',') || val.endsWith(' ')) {
          _commitToken(t);
        } else {
          // Last partial token remains in text field
          _textCtrl.value = TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          );
          return;
        }
      }
      _textCtrl.clear();
    }
  }

  void _handleInputSubmitted(String val) {
    if (val.trim().isNotEmpty) {
      _commitToken(val);
      _textCtrl.clear();
      _focusNode.requestFocus();
    }
  }

  void _removeTag(String tag) {
    final currentTags = _parseTags(widget.controller.text);
    currentTags.remove(tag);
    _syncTagsToController(currentTags);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = _parseTags(widget.controller.text);
    final totalChars = widget.controller.text.length;
    final isCharsExceeded = totalChars > widget.maxCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCharsExceeded ? AppColors.error : AppColors.border,
                width: isCharsExceeded ? 1.2 : 1.0,
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.ink.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140, maxWidth: 300),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          _textCtrl.text.isEmpty &&
                          tags.isNotEmpty) {
                        _removeTag(tags.last);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      style: TextStyle(fontSize: 13, color: AppColors.ink),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        hintText: tags.isEmpty
                            ? widget.hintText
                            : 'Add another tag...',
                        hintStyle: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onChanged: _handleInputChanged,
                      onSubmitted: _handleInputSubmitted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.platformNotice != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.platformNotice!,
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
