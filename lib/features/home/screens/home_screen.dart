import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/services/share_card_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/entry_row_parser.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/journal_entry_card.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';

/// Home — matches `docs/reference/design_htmls/screen8_home.html` (DS spacing: 6px grid).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// CSS reference `.monk { width: 195px }`; on-device display scale (larger art, less edge whitespace).
  static const double _monkCssWidthPx = 195;
  static const double _monkDisplayZoom = 1.5;
  static double get _monkDisplayWidth => _monkCssWidthPx * _monkDisplayZoom;

  static const double _monkBottomPx = 18;

  /// Visible monk art above screen bottom (1.5× display width, waist crop).
  static const double _monkVisibleHeight = 220;

  /// Space between the CTA and the monk illustration.
  static const double _ctaMonkGap = AppSpacing.lg;

  static double _collapsedBottomInset() =>
      _monkBottomPx + _monkVisibleHeight + _ctaMonkGap;

  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _greetingPhrase() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formatGreetingDate(DateTime d) =>
      '${_weekdayNames[d.weekday - 1]}, ${_monthNames[d.month - 1]} ${d.day}';

  /// Week starting Sunday (column order Sun … Sat), matching the HTML calendar.
  static List<DateTime> _weekDaysContaining(DateTime anchor) {
    final local = DateTime(anchor.year, anchor.month, anchor.day);
    final daysBack =
        local.weekday == DateTime.sunday ? 0 : local.weekday;
    final sunday = local.subtract(Duration(days: daysBack));
    return List.generate(
      7,
      (i) => sunday.add(Duration(days: i)),
    );
  }

  static String _avatarLetter() {
    if (!SupabaseService.isInitialized) return 'A';
    final user = SupabaseService.client.auth.currentUser;
    final metaName = user?.userMetadata?['name'];
    if (metaName is String && metaName.trim().isNotEmpty) {
      return metaName.trim()[0].toUpperCase();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'A';
  }

  static String _calendarLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
      case DateTime.thursday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _todayEntries = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  // Fetched for milestone / streak-broken UI (not shown on home yet).
  // ignore: unused_field
  int _longestStreak = 0;
  int _totalEntryCount = 0;
  Set<DateTime> _loggedDays = {};
  String _currentUserName = 'Someone';

  AudioPlayer? _audioPlayer;
  String? _playingEntryId;
  String? _expandedEntryId;
  StreamSubscription<PlayerState>? _playerStateSub;
  int? _sessionsRemaining;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.entryAudioPlayback) {
      final player = AudioPlayer();
      _audioPlayer = player;
      _playerStateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          if (mounted) {
            setState(() {
              _playingEntryId = null;
            });
          }
        }
      });
    }
    unawaited(_fetchTodayEntries());
  }

  @override
  void dispose() {
    final sub = _playerStateSub;
    _playerStateSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(String entryId, String audioPath) async {
    if (!FeatureFlags.entryAudioPlayback) return;
    final player = _audioPlayer;
    if (player == null) return;
    if (_playingEntryId == entryId) {
      await player.pause();
      if (mounted) setState(() => _playingEntryId = null);
      return;
    }

    try {
      await player.stop();
      final signedUrl = await Supabase.instance.client.storage
          .from('Journal-audio-files')
          .createSignedUrl(audioPath, 3600);

      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode != 200) {
        throw StateError(
          'Failed to download audio (${response.statusCode})',
        );
      }

      final dir = await getTemporaryDirectory();
      final safeName = audioPath.split('/').last.replaceAll('..', '');
      final cacheFile = File('${dir.path}/home_play_${entryId}_$safeName');
      await cacheFile.writeAsBytes(response.bodyBytes);

      await player.setAudioSource(
        AudioSource.file(cacheFile.path),
        preload: true,
      );
      if (mounted) {
        setState(() {
          _playingEntryId = entryId;
        });
      }
      unawaited(player.play());
    } catch (e) {
      if (mounted) {
        setState(() => _playingEntryId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play recording: $e')),
        );
      }
    }
  }

  static DateTime _localDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  DateTime _parseEntryCreated(Map<String, dynamic> row) {
    final raw = row['created_at'];
    if (raw is String) {
      return DateTime.parse(raw).toLocal();
    }
    return DateTime.now();
  }

  Future<void> _fetchTodayEntries() async {
    if (!SupabaseService.isInitialized) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _todayEntries = [];
          _currentStreak = 0;
          _longestStreak = 0;
          _totalEntryCount = 0;
          _loggedDays = {};
        });
      }
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _todayEntries = [];
          _currentStreak = 0;
          _longestStreak = 0;
          _totalEntryCount = 0;
          _loggedDays = {};
        });
      }
      return;
    }

    _currentUserName =
        user.userMetadata?['name']?.toString() ?? 'Someone';

    final today = _localDateOnly(DateTime.now());
    final weekDays = HomeScreen._weekDaysContaining(DateTime.now());
    final weekStartLocal = weekDays.first;
    final weekStartUtc = DateTime(
      weekStartLocal.year,
      weekStartLocal.month,
      weekStartLocal.day,
    ).toUtc();

    try {
      final entriesFuture = Supabase.instance.client
          .from('entries')
          .select(
            'id, transcript, summary, tags, mood, highlight_quote, created_at, audio_url',
          )
          .eq('user_id', user.id)
          .gte('created_at', weekStartUtc.toIso8601String())
          .order('created_at', ascending: false);

      final streakFuture = Supabase.instance.client
          .from('streaks')
          .select('current_streak, longest_streak')
          .eq('user_id', user.id)
          .maybeSingle();

      final countFuture = Supabase.instance.client
          .from('entries')
          .select('id')
          .eq('user_id', user.id)
          .count(CountOption.exact);

      final results = await Future.wait<dynamic>([
        entriesFuture,
        streakFuture,
        countFuture,
      ]);

      final list = (results[0] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      var currentStreak = 0;
      var longestStreak = 0;
      final streakRow = results[1];
      if (streakRow != null) {
        final streak = Map<String, dynamic>.from(streakRow as Map);
        currentStreak = _asInt(streak['current_streak']);
        longestStreak = _asInt(streak['longest_streak']);
      }

      final totalCount = (results[2] as PostgrestResponse).count;

      final loggedDays = <DateTime>{};
      for (final row in list) {
        final local = _parseEntryCreated(row);
        loggedDays.add(_localDateOnly(local));
      }

      final todayEntries = list.where((row) {
        return _localDateOnly(_parseEntryCreated(row)) == today;
      }).toList();

      if (!mounted) return;
      setState(() {
        _todayEntries = todayEntries;
        _currentStreak = currentStreak;
        _longestStreak = longestStreak;
        _totalEntryCount = totalCount;
        _loggedDays = loggedDays;
        _isLoading = false;
      });

      final remaining = await const SubscriptionService().sessionsRemaining();
      if (mounted) {
        setState(() => _sessionsRemaining = remaining);
        print('[Subscription] sessionsRemaining: $_sessionsRemaining');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayEntries = [];
        _currentStreak = 0;
        _longestStreak = 0;
        _totalEntryCount = 0;
        _loggedDays = {};
        _isLoading = false;
      });
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String _formatEntryTime(DateTime created) {
    final local = created.toLocal();
    var h = local.hour;
    final m = local.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }

  Widget _buildTodayEntryCard(Map<String, dynamic> entry) {
    final created = _parseEntryCreated(entry);
    final entryId = entry['id']?.toString() ?? '';
    final audioRaw = entry['audio_url'];
    final hasAudio =
        audioRaw != null && audioRaw.toString().trim().isNotEmpty;
    final transcript = parseEntryString(entry['transcript']) ?? '';
    return JournalEntryCard(
      timeLabel: _formatEntryTime(created),
      summary: parseEntryString(entry['summary']),
      tags: parseEntryTags(entry['tags']),
      mood: parseEntryString(entry['mood']),
      formattedTranscript: transcript,
      expandToFill: true,
      isExpanded: _expandedEntryId == entryId,
      onExpandedChanged: (expanded) {
        setState(() {
          _expandedEntryId = expanded ? entryId : null;
        });
      },
      isPlaying: FeatureFlags.entryAudioPlayback &&
          hasAudio &&
          _playingEntryId == entryId,
      onPlay: FeatureFlags.entryAudioPlayback && hasAudio
          ? () => unawaited(
                _togglePlay(entryId, audioRaw.toString()),
              )
          : null,
      onShare: () => unawaited(
            const ShareCardService().shareEntry(
              context: context,
              highlightQuote: entry['highlight_quote']?.toString(),
              summary: parseEntryString(entry['summary']),
              tags: parseEntryTags(entry['tags']),
              mood: parseEntryString(entry['mood']),
              userName: _currentUserName,
              createdAt: created,
              sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100),
            ),
          ),
    );
  }

  Widget _makeAnotherEntryCta() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Make another entry',
            onPressed: () => unawaited(
              SubscriptionService.navigateToSessionOrPaywall(context),
            ),
          ),
          if (_sessionsRemaining != null &&
              _sessionsRemaining! <= 2 &&
              _sessionsRemaining! > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Center(
                child: Text(
                  '$_sessionsRemaining session${_sessionsRemaining == 1 ? '' : 's'} remaining on free plan',
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntriesZone(BoxConstraints constraints) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayEntries.isEmpty) {
      return Center(
        child: Text(
          'No entries today yet',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    final hasExpandedEntry = _expandedEntryId != null;
    final zoneHeight = constraints.maxHeight;

    return Stack(
      clipBehavior: hasExpandedEntry ? Clip.none : Clip.hardEdge,
      children: [
        if (hasExpandedEntry)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _makeAnotherEntryCta(),
          ),
        ListView.separated(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          itemCount: _todayEntries.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final entry = _todayEntries[index];
            final entryId = entry['id']?.toString() ?? '';
            final card = _buildTodayEntryCard(entry);

            if (hasExpandedEntry && _expandedEntryId == entryId) {
              return SizedBox(
                height: zoneHeight,
                child: card,
              );
            }
            return card;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = HomeScreen._weekDaysContaining(today);

    final streakCount = _currentStreak;
    final totalEntries = _totalEntryCount;
    final loggedDays = _loggedDays;

    // greeting-label: 11 / w400 / #A89E8E — greeting-date: 19 / w500 / #2C2416
    final greetingSmall = _figtreeStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textTertiary,
    );
    final dateLarge = _figtreeStyle(
      fontSize: 19,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: AppColors.textPrimary,
    );
    final statNumberStreak = _figtreeStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: AppColors.streak,
    );
    final statNumberEntries = _figtreeStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: AppColors.primary,
    );
    // stat-label: 9 / w400 / #7A7060
    final statLabel = _figtreeStyle(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    // section-label: 13 / w500 / #A89E8E — view-all: 13 / w400 / #5E9A78
    final sectionStyle = _figtreeStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1,
      color: AppColors.textTertiary,
    );
    final viewAllStyle = _figtreeStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1,
      color: AppColors.primary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Layer 1 — monk (below content z-order).
          Positioned(
            left: 0,
            right: 0,
            bottom: HomeScreen._monkBottomPx,
            child: IgnorePointer(
              child: _HomeMonkEntrance(width: HomeScreen._monkDisplayWidth),
            ),
          ),
          // Layer 2 — header fixed; entries zone scrolls above CTA; expands over CTA+monk.
          Positioned.fill(
            child: SafeArea(
              bottom: _expandedEntryId == null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.screenTop,
                  AppSpacing.screenH,
                  _expandedEntryId == null
                      ? HomeScreen._collapsedBottomInset()
                      : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Greeting row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(HomeScreen._greetingPhrase(), style: greetingSmall),
                        SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                HomeScreen._formatGreetingDate(today),
                                style: dateLarge,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    context.push(AppRoutes.account),
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    HomeScreen._avatarLetter(),
                                    style: _figtreeStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 2. Stat cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: '$streakCount',
                            label: 'day streak',
                            valueStyle: statNumberStreak,
                            labelStyle: statLabel,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _StatCard(
                            value: '$totalEntries',
                            label: 'total entries',
                            valueStyle: statNumberEntries,
                            labelStyle: statLabel,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 3. Calendar strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 7; i++)
                          _CalendarDayColumn(
                            letter: HomeScreen._calendarLetter(
                              weekDays[i].weekday,
                            ),
                            dayNum: weekDays[i].day,
                            logged: loggedDays.any(
                              (d) =>
                                  d.year == weekDays[i].year &&
                                  d.month == weekDays[i].month &&
                                  d.day == weekDays[i].day,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // 4. Section row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today', style: sectionStyle),
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.journalListing),
                          child: Text('View all', style: viewAllStyle),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // 5. Entries zone — bounded above CTA; full height when expanded.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            _buildEntriesZone(constraints),
                      ),
                    ),

                    // 6. CTA — visible only when all entries collapsed.
                    if (_expandedEntryId == null) _makeAnotherEntryCta(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `.monk` + DS §9: `opacity` 0→1, `translateY` 8px→0, **600ms** `ease-out`; centered (`left:50%` / `translateX(-50%)`).
class _HomeMonkEntrance extends StatefulWidget {
  const _HomeMonkEntrance({required this.width});

  final double width;

  @override
  State<_HomeMonkEntrance> createState() => _HomeMonkEntranceState();
}

class _HomeMonkEntranceState extends State<_HomeMonkEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _translateY = Tween<double>(begin: 8, end: 0).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: MonkMascot(
          state: MonkState.watering,
          width: widget.width,
          multiplyWithBackground: true,
        ),
      ),
    );
  }
}

TextStyle _figtreeStyle({
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueStyle,
    required this.labelStyle,
  });

  final String value;
  final String label;
  final TextStyle valueStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: valueStyle),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

class _CalendarDayColumn extends StatelessWidget {
  const _CalendarDayColumn({
    required this.letter,
    required this.dayNum,
    required this.logged,
  });

  final String letter;
  final int dayNum;
  final bool logged;

  @override
  Widget build(BuildContext context) {
    // cal-ltr: 9 / w400 / #A89E8E @ 0.55 — cal-num: 13 / w500 / #A89E8E (logged: #5E9A78)
    final letterStyle = _figtreeStyle(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      height: 1,
      color: AppColors.textTertiary.withValues(alpha: 0.55),
    );
    final numColor =
        logged ? AppColors.primary : AppColors.textTertiary;
    final numStyle = _figtreeStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1,
      color: numColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(letter, style: letterStyle),
        SizedBox(height: AppSpacing.xs),
        Text('$dayNum', style: numStyle),
      ],
    );
  }
}
