import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/feature_flags.dart';
import '../../../core/services/share_card_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/entry_row_parser.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/journal_entry_card.dart';

/// Matches `docs/reference/design_htmls/Journal listing.html`.
class JournalListingScreen extends StatefulWidget {
  const JournalListingScreen({super.key});

  @override
  State<JournalListingScreen> createState() => _JournalListingScreenState();
}

class _JournalListingScreenState extends State<JournalListingScreen> {
  List<_JournalDateGroup> _groups = [];
  bool _isLoading = true;
  bool _fetchError = false;
  String _currentUserName = 'Someone';

  AudioPlayer? _audioPlayer;
  String? _playingEntryId;
  StreamSubscription<PlayerState>? _playerStateSub;

  static const List<String> _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _currentUserName = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['name']
            ?.toString() ??
        'Someone';
    if (FeatureFlags.entryAudioPlayback) {
      final player = AudioPlayer();
      _audioPlayer = player;
      _playerStateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          if (mounted) {
            setState(() => _playingEntryId = null);
          }
        }
      });
    }
    unawaited(_fetchEntries());
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

  Future<void> _fetchEntries() async {
    if (!SupabaseService.isInitialized) {
      if (mounted) {
        setState(() {
          _groups = [];
          _isLoading = false;
          _fetchError = false;
        });
      }
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _groups = [];
          _isLoading = false;
          _fetchError = false;
        });
      }
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('entries')
          .select(
            'id, transcript, summary, tags, mood, highlight_quote, created_at, audio_url',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _groups = _groupEntries(list);
        _isLoading = false;
        _fetchError = false;
      });
    } catch (e) {
      print('[EdgeState] journal fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _groups = [];
        _fetchError = true;
        _isLoading = false;
      });
    }
  }

  DateTime _parseCreated(Map<String, dynamic> row) {
    final raw = row['created_at'];
    if (raw is String) {
      return DateTime.parse(raw).toLocal();
    }
    return DateTime.now();
  }

  String _dateGroupLabel(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return '${_weekdayShort[local.weekday - 1]}, '
        '${_monthShort[local.month - 1]} ${local.day}';
  }

  String _formatEntryTime(DateTime created) {
    var h = created.hour;
    final m = created.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  }

  _JournalEntry _mapRowToJournalEntry(Map<String, dynamic> row) {
    final created = _parseCreated(row);
    final transcript = parseEntryString(row['transcript']) ?? '';
    final audioRaw = row['audio_url'];
    return _JournalEntry(
      id: row['id']?.toString() ?? '',
      timeLabel: _formatEntryTime(created),
      summary: parseEntryString(row['summary']),
      tags: parseEntryTags(row['tags']),
      mood: parseEntryString(row['mood']),
      highlightQuote: parseEntryString(row['highlight_quote']),
      createdAt: created,
      formattedTranscript: transcript,
      audioUrl: audioRaw != null && audioRaw.toString().trim().isNotEmpty
          ? audioRaw.toString()
          : null,
    );
  }

  List<_JournalDateGroup> _groupEntries(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];

    final groups = <_JournalDateGroup>[];
    String? currentLabel;
    final currentEntries = <_JournalEntry>[];

    for (final row in rows) {
      final label = _dateGroupLabel(_parseCreated(row));
      final entry = _mapRowToJournalEntry(row);

      if (label != currentLabel) {
        if (currentLabel != null) {
          groups.add(
            _JournalDateGroup(
              label: currentLabel,
              entries: List<_JournalEntry>.from(currentEntries),
            ),
          );
          currentEntries.clear();
        }
        currentLabel = label;
      }
      currentEntries.add(entry);
    }

    if (currentLabel != null && currentEntries.isNotEmpty) {
      groups.add(
        _JournalDateGroup(
          label: currentLabel,
          entries: List<_JournalEntry>.from(currentEntries),
        ),
      );
    }

    return groups;
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
      final cacheFile = File('${dir.path}/journal_play_${entryId}_$safeName');
      await cacheFile.writeAsBytes(response.bodyBytes);

      await player.setAudioSource(
        AudioSource.file(cacheFile.path),
        preload: true,
      );
      if (mounted) {
        setState(() => _playingEntryId = entryId);
      }
      unawaited(player.play());
    } catch (e) {
      if (mounted) {
        setState(() => _playingEntryId = null);
        AppSnackBar.show(
          context,
          'Could not play recording: $e',
          isError: true,
        );
      }
    }
  }

  Widget _buildEntryCard(_JournalEntry entry) {
    final hasAudio = entry.audioUrl != null;
    return JournalEntryCard(
      timeLabel: entry.timeLabel,
      summary: entry.summary,
      tags: entry.tags,
      mood: entry.mood,
      formattedTranscript: entry.formattedTranscript,
      isPlaying: FeatureFlags.entryAudioPlayback &&
          hasAudio &&
          _playingEntryId == entry.id,
      onPlay: FeatureFlags.entryAudioPlayback && hasAudio
          ? () => unawaited(_togglePlay(entry.id, entry.audioUrl!))
          : null,
      onShare: () => unawaited(
            const ShareCardService().shareEntry(
              context: context,
              highlightQuote: entry.highlightQuote,
              summary: entry.summary,
              tags: entry.tags,
              mood: entry.mood,
              userName: _currentUserName,
              createdAt: entry.createdAt,
              sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100),
            ),
          ),
    );
  }

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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _fetchError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Could not load journal',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              GestureDetector(
                                onTap: () {
                                  print('[EdgeState] journal retry tapped');
                                  setState(() {
                                    _fetchError = false;
                                    _isLoading = true;
                                  });
                                  unawaited(_fetchEntries());
                                },
                                child: Text(
                                  'Tap to retry',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                  : _groups.isEmpty
                      ? Center(
                          child: Text(
                            'No entries yet',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH,
                            0,
                            AppSpacing.screenH,
                            AppSpacing.screenBot,
                          ),
                          itemCount: _groups.length,
                          itemBuilder: (context, gi) {
                            final g = _groups[gi];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: gi < _groups.length - 1
                                    ? AppSpacing.md
                                    : 0,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                    ),
                                    child: Text(g.label, style: dateLabelStyle),
                                  ),
                                  for (var ei = 0; ei < g.entries.length; ei++) ...[
                                    if (ei > 0) SizedBox(height: AppSpacing.xs),
                                    _buildEntryCard(g.entries[ei]),
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
    required this.id,
    required this.timeLabel,
    this.summary,
    this.tags = const [],
    this.mood,
    this.highlightQuote,
    required this.createdAt,
    required this.formattedTranscript,
    this.audioUrl,
  });

  final String id;
  final String timeLabel;
  final String? summary;
  final List<String> tags;
  final String? mood;
  final String? highlightQuote;
  final DateTime createdAt;
  final String formattedTranscript;
  final String? audioUrl;
}
