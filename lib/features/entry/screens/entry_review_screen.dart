import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/onboarding/onboarding_progress_visibility.dart';
import '../../../core/services/audio_upload_service.dart';
import '../../../core/services/entry_enrichment_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/formatted_transcript.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/thankful_app_title.dart';

/// Entry review — matches `docs/reference/design_htmls/Post_entry_review_screen.html`.
///
/// **Onboarding:** pass [showOnboardingProgress] true (e.g. `context.go(..., extra: true)`)
/// for step **5** of **6** — Thankful title + dot strip; Save continues to paywall.
///
/// **Returning user:** `showOnboardingProgress` false — no progress UI; Save returns home.
///
/// **Recording:** optional `?recordingPath=` query (absolute path to local `.m4a`).
/// Transcript + playback live in one surface card like the reference HTML.
class EntryReviewScreen extends StatefulWidget {
  const EntryReviewScreen({
    super.key,
    this.showOnboardingProgress = false,
    this.initialRecordingPath,
    this.initialTranscript,
  });

  /// Dot strip + app title (first-time onboarding only).
  final bool showOnboardingProgress;

  /// When set (e.g. from [EntryReviewExtra]), used if `recordingPath` query is absent.
  final String? initialRecordingPath;

  /// Pre-filled session transcript (skips Whisper when non-empty).
  final String? initialTranscript;

  static const int totalSteps = 6;
  static const int currentStep = 5;

  static const Color _dotIdle = Color(0xFFD8D2CA);

  static const List<String> _loadingMessages = [
    'Gathering your words...',
    'Finding what mattered...',
    'Reading between the lines...',
    'Almost ready...',
  ];

  @override
  State<EntryReviewScreen> createState() => _EntryReviewScreenState();
}

class _EntryReviewScreenState extends State<EntryReviewScreen>
    with TickerProviderStateMixin {
  String? _recordingPath;
  bool _audioSourceLoaded = false;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  String? _transcript;
  EntryEnrichment? _enrichment;
  bool _isTranscribing = false;
  bool _isEnriching = false;
  String? _transcriptionError;
  bool _isSaving = false;
  bool _showOnboardingProgress = false;

  late final AnimationController _revealController;
  late final Animation<double> _summaryFade;
  late final Animation<double> _summaryDrift;
  late final Animation<double> _pillsFade;
  late final Animation<double> _pillsDrift;
  late final Animation<double> _transcriptFade;
  late final Animation<double> _transcriptDrift;

  int _loadingMessageIndex = 0;
  Timer? _loadingMessageTimer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _summaryFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _summaryDrift = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _pillsFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
    );
    _pillsDrift = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
      ),
    );

    _transcriptFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _transcriptDrift = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    unawaited(_resolveOnboardingProgress());
    if (widget.initialTranscript != null &&
        widget.initialTranscript!.trim().isNotEmpty) {
      _transcript = widget.initialTranscript;
    }
    _playerStateSub = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAudioSourceThenTranscribe());
    });
  }

  void _startLoadingMessages() {
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = Timer.periodic(
      const Duration(milliseconds: 1800),
      (_) {
        if (!mounted) return;
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % EntryReviewScreen._loadingMessages.length;
        });
      },
    );
  }

  void _stopLoadingMessages() {
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = null;
  }

  void _triggerRevealAnimation() {
    print('[EntryReview] Enrichment complete — triggering reveal animation');
    _revealController.forward(from: 0);
    print(
      '[EntryReview] Reveal animation started — summary, pills, transcript staggered 480ms',
    );
  }

  Future<void> _resolveOnboardingProgress() async {
    final show = await OnboardingProgressVisibility.shouldShowProgressStrip();
    if (!mounted) return;
    setState(() => _showOnboardingProgress = show);
  }

  Future<void> _loadAudioSourceThenTranscribe() async {
    final path = _recordingPath;
    if (path == null || path.isEmpty) return;

    final skipTranscription =
        _transcript != null && _transcript!.trim().isNotEmpty;

    if (!mounted) return;
    if (!skipTranscription) {
      _loadingMessageIndex = 0;
      _startLoadingMessages();
      setState(() {
        _isTranscribing = true;
        _transcriptionError = null;
      });
    }

    try {
      await _ensureAudioSourceLoaded();
      if (skipTranscription) {
        if (mounted) {
          setState(() {
            _isTranscribing = false;
            _transcriptionError = null;
          });
          print('Raw transcript for enrichment: $_transcript');
          await _runEnrichment(_transcript!);
        }
        return;
      }
      final text = await const TranscriptionService().transcribeAudio(path);
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcript = text;
        _transcriptionError = null;
      });
      print('Raw transcript for enrichment: $_transcript');
      await _runEnrichment(text);
    } catch (e) {
      if (!mounted) return;
      _stopLoadingMessages();
      setState(() {
        _isTranscribing = false;
        _transcriptionError = e.toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final raw =
        GoRouterState.of(context).uri.queryParameters['recordingPath'];
    developer.log(
      'DEBUG recordingPath: $raw',
      name: 'Thankful.EntryReview',
    );
    if (_recordingPath == null && raw != null && raw.isNotEmpty) {
      // Query values are usually decoded once; decode again if the path was
      // over-encoded when navigating.
      _recordingPath = Uri.decodeFull(raw);
    }
    if (_recordingPath == null &&
        widget.initialRecordingPath != null &&
        widget.initialRecordingPath!.isNotEmpty) {
      _recordingPath = widget.initialRecordingPath;
    }
  }

  @override
  void dispose() {
    unawaited(_playerStateSub?.cancel());
    _player.dispose();
    _revealController.dispose();
    _loadingMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _runEnrichment(String rawTranscript) async {
    if (!mounted) return;
    _loadingMessageIndex = 0;
    _startLoadingMessages();
    setState(() => _isEnriching = true);
    try {
      final enrichment =
          await const EntryEnrichmentService().enrich(rawTranscript);
      if (!mounted) return;
      setState(() {
        _enrichment = enrichment;
        _transcript = enrichment.formattedTranscript;
        _isEnriching = false;
      });
      _stopLoadingMessages();
      _triggerRevealAnimation();
    } catch (e) {
      developer.log('Enrichment failed: $e', name: 'Thankful.EntryReview');
      if (!mounted) return;
      setState(() {
        _enrichment = EntryEnrichment.quietMomentFallback(rawTranscript);
        _transcript = rawTranscript;
        _isEnriching = false;
      });
      _stopLoadingMessages();
      _triggerRevealAnimation();
    }
  }

  Widget _buildWaitingState(BuildContext context) {
    print(
      '[EntryReview] Showing waiting state — isTranscribing: $_isTranscribing | isEnriching: $_isEnriching',
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonkMascot(
              state: MonkState.writing,
              width: MediaQuery.sizeOf(context).width * 0.45,
              multiplyWithBackground: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Text(
                EntryReviewScreen._loadingMessages[_loadingMessageIndex],
                key: ValueKey(_loadingMessageIndex),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _pillTextStyle => AppTextStyles.caption.copyWith(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: _pillTextStyle),
    );
  }

  String _metaLine(DateTime d) {
    const months = <String>[
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _ensureAudioSourceLoaded() async {
    final path = _recordingPath;
    if (path == null || path.isEmpty) return false;
    if (_audioSourceLoaded) return true;

    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording file not found. It may have been deleted, or the '
              'path was lost in navigation.\n$path',
            ),
          ),
        );
      }
      return false;
    }

    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(path)),
        preload: true,
      );
      _audioSourceLoaded = true;
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open recording for playback: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _togglePlayPause() async {
    final path = _recordingPath;
    if (path == null || path.isEmpty) return;

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (!await _ensureAudioSourceLoaded()) return;
        await _player.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Widget _transcriptArea(bool hasRecording) {
    if (!hasRecording) {
      return Text(
        'Transcription will appear here...',
        style: AppTextStyles.journal,
      );
    }
    if (_transcriptionError != null) {
      return Text(
        _transcriptionError!,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }
    if (_transcript != null) {
      return AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) => Opacity(
          opacity: _transcriptFade.value,
          child: Transform.translate(
            offset: Offset(0, _transcriptDrift.value),
            child: child,
          ),
        ),
        child: FormattedTranscript(transcript: _transcript!),
      );
    }
    return Text(
      'Transcription will appear here...',
      style: AppTextStyles.journal,
    );
  }

  Future<void> _onSaveEntry() async {
    if (_isSaving) return;

    final localPath = _recordingPath;
    if (localPath == null || localPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording to save.')),
      );
      return;
    }

    if (_isTranscribing || _isEnriching) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for your entry to finish preparing.'),
        ),
      );
      return;
    }

    if (!SupabaseService.isInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supabase is not configured. Cannot save this entry yet.',
          ),
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final row = <String, dynamic>{
        'user_id': user.id,
        'transcript':
            _enrichment?.formattedTranscript ?? _transcript ?? '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'summary': _enrichment?.summary,
        'tags': _enrichment?.tags,
        'mood': _enrichment?.mood,
        'highlight_quote': _enrichment?.highlightQuote,
      };
      if (FeatureFlags.entryAudioPlayback) {
        final storagePath = await const AudioUploadService().uploadAudio(
          localPath,
          user.id,
        );
        row['audio_url'] = storagePath;
      }
      await Supabase.instance.client.from('entries').insert(row);
      await const StreakService().updateStreakAfterEntry(user.id);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (_showOnboardingProgress) {
        await Supabase.instance.client
            .from('users')
            .update({'onboarding_complete': true}).eq('id', user.id);
        if (!mounted) return;
        context.go(AppRoutes.paywall, extra: true);
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save entry: $e')),
      );
    }
  }

  Widget _buildEntryContent(BuildContext context, DateTime now, bool hasRecording) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showOnboardingProgress) ...[
            const ThankfulAppTitle(),
            const SizedBox(height: AppSpacing.xs),
            OnboardingProgressBar(
              totalSteps: EntryReviewScreen.totalSteps,
              currentStep: EntryReviewScreen.currentStep,
              gap: 4,
              inactiveColor: EntryReviewScreen._dotIdle,
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 48),
          Text('Your entry', style: AppTextStyles.heading1),
          Text(
            'is ready',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.primary,
            ),
          ),
          if (_enrichment != null) ...[
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) => Opacity(
                opacity: _summaryFade.value,
                child: Transform.translate(
                  offset: Offset(0, _summaryDrift.value),
                  child: child,
                ),
              ),
              child: Text(
                _enrichment!.summary,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) => Opacity(
                opacity: _pillsFade.value,
                child: Transform.translate(
                  offset: Offset(0, _pillsDrift.value),
                  child: child,
                ),
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs / 2,
                children: [
                  _buildPill(_enrichment!.mood),
                  for (final tag in _enrichment!.tags) _buildPill(tag),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            height: 204,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onPressed: hasRecording ? _togglePlayPause : null,
                      icon: Icon(
                        _player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: hasRecording
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snapshot) {
                          final pos = snapshot.data ?? Duration.zero;
                          final dur = _player.duration ?? Duration.zero;
                          if (dur == Duration.zero) {
                            return Text(
                              '--:--',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return Text(
                            '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _transcriptArea(hasRecording),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _metaLine(now),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();
    final hasRecording =
        _recordingPath != null && _recordingPath!.isNotEmpty;
    final isLoading = _isTranscribing || _isEnriching;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading)
              Expanded(child: _buildWaitingState(context))
            else
              Expanded(child: _buildEntryContent(context, now, hasRecording)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Save entry',
                    isLoading: _isSaving,
                    onPressed: (_isSaving || _isTranscribing || _isEnriching)
                        ? null
                        : () => unawaited(_onSaveEntry()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Start over',
                    onPressed: isLoading
                        ? null
                        : () => unawaited(
                              SubscriptionService.navigateToSessionOrPaywall(
                                context,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
