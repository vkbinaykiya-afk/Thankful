import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class EntryCard extends StatelessWidget {
  final String dateLabel;
  final String body;
  final String typeLabel;
  final String time;
  final VoidCallback? onTap;

  const EntryCard({
    super.key,
    required this.dateLabel,
    required this.body,
    required this.typeLabel,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStyle = GoogleFonts.figtree(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textTertiary,
    );
    final bodyStyle = GoogleFonts.figtree(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textJournal,
    );
    final metaTypeStyle = GoogleFonts.figtree(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.primary,
    );
    final metaTimeStyle = GoogleFonts.figtree(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textTertiary,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: dateStyle),
            const SizedBox(height: 6),
            Text(body, style: bodyStyle),
            const SizedBox(height: 8),
            Container(height: 0.5, color: AppColors.surfaceRaised),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(typeLabel, style: metaTypeStyle),
                const SizedBox(width: 8),
                Text('·', style: metaTimeStyle),
                const SizedBox(width: 8),
                Text(time, style: metaTimeStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
