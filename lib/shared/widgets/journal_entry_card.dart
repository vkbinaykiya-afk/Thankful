import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Home + journal listing — `Journal listing.html` / `screen8_home` entry card.
class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    super.key,
    required this.timeLabel,
    required this.body,
    required this.durationLabel,
    this.onPlay,
    this.onShare,
    this.onTap,
    this.isPlaying = false,
  });

  final String timeLabel;
  final String body;
  final String durationLabel;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final dateStyle = _jeFigtree(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textTertiary,
    );
    final bodyStyle = _jeFigtree(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: AppColors.textJournal,
    );
    final metaStyle = _jeFigtree(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textTertiary,
    );

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(timeLabel, style: dateStyle),
                ),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Container(
                    height: 0.5,
                    color: AppColors.surfaceRaised,
                  ),
                ),
                Text(durationLabel, style: metaStyle),
              ],
            ),
          ),
          if (onPlay != null) ...[
            const SizedBox(width: 12),
            Material(
              color: AppColors.surfaceRaised,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPlay,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Material(
            color: AppColors.surfaceRaised,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (onShare != null) {
                  onShare!();
                  return;
                }
                unawaited(
                  Share.shareXFiles(
                    [
                      XFile.fromData(
                        Uint8List.fromList(utf8.encode(body)),
                        mimeType: 'text/plain',
                        name: 'thankful-entry.txt',
                      ),
                    ],
                  ),
                );
              },
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.share_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }
    return card;
  }
}

TextStyle _jeFigtree({
  required double fontSize,
  required FontWeight fontWeight,
  required double height,
  required Color color,
}) =>
    AppTextStyles.captionMedium.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
