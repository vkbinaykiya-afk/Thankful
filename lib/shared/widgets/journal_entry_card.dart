import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'formatted_transcript.dart';

/// Home + journal listing — collapsed summary card, expandable transcript.
class JournalEntryCard extends StatefulWidget {
  const JournalEntryCard({
    super.key,
    required this.timeLabel,
    this.summary,
    this.tags = const [],
    this.mood,
    this.formattedTranscript,
    this.onPlay,
    this.onShare,
    this.isPlaying = false,
    this.isExpanded,
    this.onExpandedChanged,
    this.expandToFill = false,
  });

  final String timeLabel;
  final String? summary;
  final List<String> tags;
  final String? mood;
  final String? formattedTranscript;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final bool isPlaying;

  /// When set, expansion is controlled by the parent (e.g. home overlay layout).
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  /// When true and expanded, fills parent height (home screen overlay mode).
  final bool expandToFill;

  @override
  State<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<JournalEntryCard> {
  static const _expandDuration = Duration(milliseconds: 220);

  bool _expandedInternal = false;

  bool get _isExpanded => widget.isExpanded ?? _expandedInternal;

  void _toggleExpanded() {
    final next = !_isExpanded;
    if (widget.isExpanded != null) {
      widget.onExpandedChanged?.call(next);
    } else {
      setState(() => _expandedInternal = next);
      widget.onExpandedChanged?.call(next);
    }
  }

  TextStyle get _timeStyle => AppTextStyles.captionMedium.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  TextStyle get _summaryStyle => AppTextStyles.captionMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textJournal,
      );

  TextStyle get _pillTextStyle => AppTextStyles.caption.copyWith(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  String get _displaySummary {
    final s = widget.summary?.trim();
    if (s != null && s.isNotEmpty) return s;
    final t = widget.formattedTranscript?.trim();
    if (t != null && t.isNotEmpty) return t;
    return '';
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: _pillTextStyle),
    );
  }

  Widget _moodAndTagsRow() {
    final mood = widget.mood?.trim();
    final hasMood = mood != null && mood.isNotEmpty;
    if (!hasMood && widget.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs / 2,
        children: [
          if (hasMood) _pill(mood),
          for (final tag in widget.tags) _pill(tag),
        ],
      ),
    );
  }

  Widget _collapsedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.timeLabel, style: _timeStyle),
        if (_displaySummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _displaySummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _summaryStyle,
          ),
        ],
        _moodAndTagsRow(),
      ],
    );
  }

  Widget _expandedContent() {
    final transcript = widget.formattedTranscript?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.timeLabel, style: _timeStyle),
        if (transcript.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          FormattedTranscript(
            transcript: transcript,
            style: _summaryStyle,
          ),
        ] else if (_displaySummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_displaySummary, style: _summaryStyle),
        ],
        _moodAndTagsRow(),
      ],
    );
  }

  void _onShareTap() {
    if (widget.onShare != null) {
      widget.onShare!();
      return;
    }
    final text = widget.formattedTranscript?.trim().isNotEmpty == true
        ? widget.formattedTranscript!
        : _displaySummary;
    if (text.isEmpty) return;
    unawaited(
      Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(text)),
            mimeType: 'text/plain',
            name: 'thankful-entry.txt',
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _actionsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded && widget.onPlay != null) ...[
          _actionButton(
            icon: widget.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            onTap: widget.onPlay!,
          ),
          const SizedBox(height: 12),
        ],
        _actionButton(
          icon: Icons.share_rounded,
          onTap: _onShareTap,
        ),
      ],
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: child,
    );
  }

  Widget _contentArea() {
    if (_isExpanded && widget.expandToFill) {
      return Expanded(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _expandedContent(),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _isExpanded ? _expandedContent() : _collapsedContent(),
        ),
      ),
    );
  }

  Widget _cardRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _contentArea(),
        const SizedBox(width: 12),
        _actionsColumn(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _cardShell(child: _cardRow());

    if (_isExpanded && widget.expandToFill) {
      return Material(
        color: Colors.transparent,
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: card,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedSize(
        duration: _expandDuration,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _cardShell(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _isExpanded
                        ? _expandedContent()
                        : _collapsedContent(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _actionsColumn(),
            ],
          ),
        ),
      ),
    );
  }
}
