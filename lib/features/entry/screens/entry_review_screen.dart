import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/transcription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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
  });

  /// Dot strip + app title (first-time onboarding only).
  final bool showOnboardingProgress;

  static const int totalSteps = 6;
  static const int currentStep = 5;

  static const Color _dotIdle = Color(0xFFD8D2CA);

  @override
  State<EntryReviewScreen> createState() => _EntryReviewScreenState();
}

class _EntryReviewScreenState extends State<EntryReviewScreen> {
  String? _recordingPath;
  bool _audioSourceLoaded = false;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  String? _transcript;
  bool _isTranscribing = false;
  String? _transcriptionError;

  @override
  void initState() {
    super.initState();
    _playerStateSub = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAudioSourceThenTranscribe());
    });
  }

  Future<void> _loadAudioSourceThenTranscribe() async {
    final path = _recordingPath;
    if (path == null || path.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isTranscribing = true;
      _transcriptionError = null;
    });

    try {
      await _ensureAudioSourceLoaded();
      final text = await const TranscriptionService().transcribeAudio(path);
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcript = text;
        _transcriptionError = null;
      });
    } catch (e) {
      if (!mounted) return;
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
  }

  @override
  void dispose() {
    unawaited(_playerStateSub?.cancel());
    _player.dispose();
    super.dispose();
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
    return '${months[d.month - 1]} ${d.day}, ${d.year} · 4 min 12 sec';
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
    if (_isTranscribing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    if (_transcriptionError != null) {
      return Text(
        _transcriptionError!,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }
    if (_transcript != null) {
      return Text(_transcript!, style: AppTextStyles.journal);
    }
    return Text(
      'Transcription will appear here...',
      style: AppTextStyles.journal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();
    final hasRecording =
        _recordingPath != null && _recordingPath!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showOnboardingProgress) ...[
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _metaLine(now),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // One journal card: playback row + transcript (HTML `.card`).
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
                                onPressed:
                                    hasRecording ? _togglePlayPause : null,
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
                                    final pos =
                                        snapshot.data ?? Duration.zero;
                                    final dur =
                                        _player.duration ?? Duration.zero;
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
                    const Spacer(),
                  ],
                ),
              ),
            ),
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
                    onPressed: () {
                      if (widget.showOnboardingProgress) {
                        context.go(AppRoutes.paywall, extra: true);
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Start over',
                    onPressed: () =>
                        context.go(AppRoutes.onboardingConvo),
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
