import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Renders a session transcript with speaker labels and `**keyword**` bold.
class FormattedTranscript extends StatelessWidget {
  const FormattedTranscript({
    super.key,
    required this.transcript,
    this.style,
  });

  final String transcript;
  final TextStyle? style;

  static final RegExp _markdownBold = RegExp(r'\*\*(.+?)\*\*');

  TextStyle get _bodyStyle => style ?? AppTextStyles.journal;

  @override
  Widget build(BuildContext context) {
    final lines = transcript.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          RichText(
            textDirection: TextDirection.ltr,
            text: TextSpan(
              style: _bodyStyle.copyWith(color: null),
              children: [_lineSpan(lines[i])],
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _spansWithMarkdownBold(String content) {
    final bodyStyle = _bodyStyle;
    final boldStyle = bodyStyle.copyWith(fontWeight: FontWeight.w500);
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _markdownBold.allMatches(content)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: content.substring(start, match.start),
            style: bodyStyle,
          ),
        );
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      start = match.end;
    }
    if (start < content.length) {
      spans.add(TextSpan(text: content.substring(start), style: bodyStyle));
    }
    return spans;
  }

  TextSpan _lineSpan(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return const TextSpan(text: '');
    }

    const lhamoPrefix = 'Lhamo:';
    const youPrefix = 'You:';

    if (trimmed.startsWith(lhamoPrefix)) {
      final content = trimmed.substring(lhamoPrefix.length).trimLeft();
      return TextSpan(
        children: [
          TextSpan(
            text: lhamoPrefix,
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          if (content.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(text: content, style: _bodyStyle),
          ],
        ],
      );
    }

    if (trimmed.startsWith(youPrefix)) {
      final content = trimmed.substring(youPrefix.length).trimLeft();
      return TextSpan(
        children: [
          TextSpan(
            text: youPrefix,
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (content.isNotEmpty) ...[
            const TextSpan(text: ' '),
            ..._spansWithMarkdownBold(content),
          ],
        ],
      );
    }

    return TextSpan(text: line, style: _bodyStyle);
  }
}
