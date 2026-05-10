import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/journal_entry_card.dart';

/// Matches `docs/reference/design_htmls/Journal listing.html`.
class JournalListingScreen extends StatelessWidget {
  const JournalListingScreen({super.key});

  static final List<_JournalDateGroup> _demoGroups = [
    _JournalDateGroup(
      label: 'Today',
      entries: [
        _JournalEntry(
          timeLabel: '9:14 AM',
          body:
              'Today I woke up feeling a quiet kind of grateful. Not the big, loud kind — just a small warmth when I made my tea.',
          durationLabel: '4 min 12 sec',
        ),
        _JournalEntry(
          timeLabel: '2:38 PM',
          body:
              'Walked by the park on the way back. Stopped for a moment. Didn\'t need to — just wanted to. That felt like something.',
          durationLabel: '1 min 48 sec',
        ),
      ],
    ),
    _JournalDateGroup(
      label: 'Wed, May 7',
      entries: [
        _JournalEntry(
          timeLabel: '8:02 AM',
          body:
              'Slept well for the first time in a while. Woke up before my alarm. That small thing felt like a win.',
          durationLabel: '2 min 55 sec',
        ),
      ],
    ),
    _JournalDateGroup(
      label: 'Tue, May 6',
      entries: [
        _JournalEntry(
          timeLabel: '9:47 PM',
          body:
              'Grateful for the call with Priya. We hadn\'t spoken properly in months. She remembered something I had completely forgotten about myself.',
          durationLabel: '5 min 30 sec',
        ),
      ],
    ),
    _JournalDateGroup(
      label: 'Sun, May 4',
      entries: [
        _JournalEntry(
          timeLabel: '10:15 AM',
          body:
              'Made breakfast slowly. No phone, no podcast. Just the sounds of the kitchen. I\'d forgotten how good that feels.',
          durationLabel: '3 min 12 sec',
        ),
      ],
    ),
    _JournalDateGroup(
      label: 'Sat, May 3',
      entries: [
        _JournalEntry(
          timeLabel: '7:50 AM',
          body:
              'Early morning. Light came in at an angle I hadn\'t noticed before. Grateful for the window, honestly.',
          durationLabel: '2 min 04 sec',
        ),
      ],
    ),
    _JournalDateGroup(
      label: 'Fri, Apr 25',
      entries: [
        _JournalEntry(
          timeLabel: '8:30 AM',
          body:
              'Something shifted this week. Can\'t name it exactly. Just lighter.',
          durationLabel: '1 min 22 sec',
        ),
        _JournalEntry(
          timeLabel: '9:12 PM',
          body:
              'End of a long week. Grateful it\'s done. Grateful for the people who made it bearable.',
          durationLabel: '2 min 48 sec',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.heading3.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1,
      color: AppColors.textPrimary,
    );
    final dateLabelStyle = AppTextStyles.captionMedium.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1,
      color: AppColors.textTertiary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                10,
                AppSpacing.screenH,
                12,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.chevron_left,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text('Journal', style: titleStyle),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  AppSpacing.screenBot,
                ),
                itemCount: _demoGroups.length,
                itemBuilder: (context, gi) {
                  final g = _demoGroups[gi];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: gi < _demoGroups.length - 1 ? AppSpacing.md : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(g.label, style: dateLabelStyle),
                        ),
                        for (var ei = 0; ei < g.entries.length; ei++) ...[
                          if (ei > 0) SizedBox(height: AppSpacing.xs),
                          JournalEntryCard(
                            timeLabel: g.entries[ei].timeLabel,
                            body: g.entries[ei].body,
                            durationLabel: g.entries[ei].durationLabel,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalDateGroup {
  const _JournalDateGroup({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<_JournalEntry> entries;
}

class _JournalEntry {
  const _JournalEntry({
    required this.timeLabel,
    required this.body,
    required this.durationLabel,
  });

  final String timeLabel;
  final String body;
  final String durationLabel;
}
