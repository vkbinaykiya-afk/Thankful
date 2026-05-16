import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory, getTemporaryDirectory;
import 'package:record/record.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/cartesia_service.dart';
import '../../../core/services/deepgram_service.dart';
import '../../../core/services/lhamo_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../entry/entry_review_extra.dart';

enum ConvoState { meditating, listening, speaking }

/// Live journal / conversation UI — matches `docs/reference/design_htmls/convo-screen.html`.
///
/// Voice recording starts on load; stop navigates to entry review with `recordingPath`.
///
/// **Routed here (`AppRoutes.onboardingConvo`) when the user starts a new entry from:**
/// 1. Onb3 — CTA **Begin my first entry**
/// 2. Entry review — **Start over** (instead of save)
/// 3. Home — **Make another entry**
class OnboardingConvoScreen extends StatefulWidget {
  const OnboardingConvoScreen({super.key});

  @override
  State<OnboardingConvoScreen> createState() => _OnboardingConvoScreenState();
}

class _OnboardingConvoScreenState extends State<OnboardingConvoScreen>
    with TickerProviderStateMixin {
  static const int _pcmSampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _lhamoPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  ConvoState _convoState = ConvoState.meditating;

  StreamSubscription<RecordState>? _recordStateSub;
  StreamSubscription<Uint8List>? _micSessionSub;
  StreamSubscription<String>? _dgSub;
  DeepgramLiveSession? _deepgramSession;

  final BytesBuilder _sessionPcm = BytesBuilder(copy: false);
  final List<Map<String, String>> _conversationHistory = [];
  int _exchangeCount = 0;
  bool _lhamoSpeaking = false;
  bool _userTurn = false;
  String _fullTranscript = '';

  bool _sessionEnding = false;
  bool _awaitingUserSpeech = false;
  bool _micStreamStarted = false;
  bool _handlingFinalTranscript = false;
  bool _recorderDisposed = false;

  Timer? _timer;
  int _elapsedSeconds = 0;

  late final AnimationController _breatheController;
  late final AnimationController _blinkController;
  late final AnimationController _slowBlinkController;
  late final AnimationController _incenseController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _slowBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _incenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });

    _recordStateSub = _recorder.onStateChanged().listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startRecording();
      unawaited(_startSession());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recordStateSub?.cancel());
    unawaited(_micSessionSub?.cancel());
    unawaited(_dgSub?.cancel());
    final dgSession = _deepgramSession;
    _deepgramSession = null;
    if (dgSession != null) {
      unawaited(dgSession.close());
    }
    if (!_recorderDisposed) {
      unawaited(_recorder.dispose());
    }
    _lhamoPlayer.dispose();
    unawaited(_bgPlayer.stop());
    _bgPlayer.dispose();
    _breatheController.dispose();
    _blinkController.dispose();
    _slowBlinkController.dispose();
    _incenseController.dispose();
    super.dispose();
  }

  void _syncConvoState() {
    final next = _lhamoSpeaking
        ? ConvoState.speaking
        : (_awaitingUserSpeech && _deepgramSession != null)
            ? ConvoState.listening
            : ConvoState.meditating;
    if (next != _convoState) {
      _convoState = next;
    }
  }

  Future<void> _startBgMusic() async {
    try {
      await _bgPlayer.setAsset('assets/audio/Convo_bg_music.mp3');
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.setVolume(0.3);
      await _bgPlayer.play();
    } catch (e) {
      print('Background music failed: $e');
    }
  }

  Future<void> _stopBgMusic() async {
    try {
      await _bgPlayer.stop();
    } catch (_) {}
  }

  Future<void> _stopUserListenOnly() async {
    _awaitingUserSpeech = false;
    await _dgSub?.cancel();
    _dgSub = null;
    final session = _deepgramSession;
    _deepgramSession = null;
    if (session != null) {
      await session.close();
    }
    if (mounted) {
      setState(_syncConvoState);
    }
  }

  /// iOS often suspends the record stream after TTS playback — restart before listen.
  Future<void> _restartMicStreamForUserTurn() async {
    if (_recorderDisposed || _sessionEnding) return;
    await _micSessionSub?.cancel();
    _micSessionSub = null;
    if (_micStreamStarted) {
      try {
        await _recorder.stop();
      } catch (e) {
        print('Mic restart stop failed: $e');
      }
      _micStreamStarted = false;
    }
    await _startRecording();
    print('Mic stream restarted for user turn (started=$_micStreamStarted)');
  }

  Future<void> _playCartesiaBytes(Uint8List bytes) async {
    if (!mounted) return;
    setState(() {
      _lhamoSpeaking = true;
      _syncConvoState();
    });
    await _bgPlayer.setVolume(0.1);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/lhamo_${DateTime.now().microsecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(bytes);
    try {
      await _lhamoPlayer.stop();
      await _lhamoPlayer.setFilePath(file.path);
      await _lhamoPlayer.play();
      await _lhamoPlayer.playerStateStream.firstWhere(
        (s) =>
            s.processingState == ProcessingState.completed ||
            s.processingState == ProcessingState.idle,
      );
    } finally {
      if (mounted) {
        setState(() {
          _lhamoSpeaking = false;
          _syncConvoState();
        });
        await _bgPlayer.setVolume(0.3);
      }
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> _startSession() async {
    unawaited(_startBgMusic());
    if (mounted) {
      setState(() {
        _convoState = ConvoState.meditating;
      });
    }
    try {
      final opening = await const LhamoService().getResponse(
        history: [],
        userMessage: '',
        exchangeCount: 0,
        isClosing: false,
      );
      final audio = await const CartesiaService().speak(opening);
      if (!mounted) return;
      await _playCartesiaBytes(audio);
      if (!mounted) return;
      setState(() {
        _fullTranscript += 'Lhamo: $opening\n\n';
        _userTurn = true;
        _syncConvoState();
      });
      print('_userTurn=true after opening (micStreamStarted=$_micStreamStarted)');
      print('Opening done - starting to listen');
      await _beginListeningForUser();
    } catch (e) {
      print('Lhamo opening failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start session: $e')),
        );
      }
    }
  }

  Future<void> _beginListeningForUser() async {
    if (_sessionEnding || !mounted || !_userTurn) {
      print(
        '_beginListeningForUser skipped: ending=$_sessionEnding '
        'mounted=$mounted userTurn=$_userTurn',
      );
      return;
    }
    print('_beginListeningForUser starting (micStreamStarted=$_micStreamStarted)');
    await _stopUserListenOnly();
    if (_sessionEnding || !mounted) return;

    await _restartMicStreamForUserTurn();
    if (_sessionEnding || !mounted) return;

    _awaitingUserSpeech = true;
    if (mounted) {
      setState(_syncConvoState);
    }
    try {
      _deepgramSession = await const DeepgramService().startLiveSession();
      print('Deepgram live session started');
      if (mounted) {
        setState(_syncConvoState);
      }
    } catch (e, st) {
      print('Deepgram live session failed: $e\n$st');
      _awaitingUserSpeech = false;
      if (mounted) {
        setState(_syncConvoState);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start listening: $e')),
        );
      }
      return;
    }

    _dgSub = _deepgramSession!.transcriptStream.listen(
      (text) {
        print('Deepgram transcript: $text');
        final t = text.trim();
        if (t.isEmpty || _sessionEnding || !_awaitingUserSpeech) return;
        unawaited(_onUserFinalTranscript(t));
      },
      onError: (Object e, StackTrace st) {
        print('Deepgram error: $e\n$st');
      },
    );

    if (mounted) setState(() {});
  }

  Future<void> _onUserFinalTranscript(String text) async {
    if (_handlingFinalTranscript || _sessionEnding || !_awaitingUserSpeech) {
      return;
    }
    _handlingFinalTranscript = true;
    _awaitingUserSpeech = false;
    await _stopUserListenOnly();

    if (!mounted) {
      _handlingFinalTranscript = false;
      return;
    }

    setState(() {
      _fullTranscript += 'You: $text\n\n';
      _syncConvoState();
    });

    try {
      await _getLhamoResponse(text);
    } finally {
      _handlingFinalTranscript = false;
    }
  }

  Future<void> _getLhamoResponse(String userMessage) async {
    if (_sessionEnding || !mounted) return;

    if (mounted) {
      setState(() {
        _convoState = ConvoState.meditating;
      });
    }

    try {
      final reply = await const LhamoService().getResponse(
        history: List<Map<String, String>>.from(_conversationHistory),
        userMessage: userMessage,
        exchangeCount: _exchangeCount,
        isClosing: false,
      );

      _conversationHistory.add({'role': 'user', 'content': userMessage});

      final audio = await const CartesiaService().speak(reply);
      if (!mounted) return;
      await _playCartesiaBytes(audio);
      if (!mounted) return;

      _conversationHistory.add({'role': 'assistant', 'content': reply});
      setState(() {
        _fullTranscript += 'Lhamo: $reply\n\n';
        _syncConvoState();
      });

      _exchangeCount++;
      if (_exchangeCount >= 5) {
        await _closeSession();
        return;
      } else {
        _userTurn = true;
        if (mounted) await _beginListeningForUser();
      }
    } catch (e) {
      print('Lhamo response failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation error: $e')),
        );
        _userTurn = true;
        await _beginListeningForUser();
      }
    }
  }

  Future<void> _closeSession({bool isEarly = false}) async {
    print('_closeSession called isEarly=$isEarly sessionEnding=$_sessionEnding');
    _sessionEnding = true;
    _userTurn = false;
    _awaitingUserSpeech = false;
    await _stopBgMusic();
    if (mounted) {
      setState(() {
        _convoState = ConvoState.meditating;
      });
    }

    if (isEarly) {
      print('Session closed early (user stop)');
    }
    await _stopUserListenOnly();

    try {
      final closing = await const LhamoService().getResponse(
        history: List<Map<String, String>>.from(_conversationHistory),
        userMessage: '',
        exchangeCount: _exchangeCount,
        isClosing: true,
      );
      final bytes = await const CartesiaService().speak(closing);
      if (mounted) {
        await _playCartesiaBytes(bytes);
        setState(() {
          _fullTranscript += 'Lhamo: $closing\n\n';
        });
      }
    } catch (e) {
      print('Closing line failed: $e');
    }

    await _stopMicStreamSubscription();
    try {
      await _recorder.stop();
      print('Recorder stopped');
    } catch (e) {
      print('Recorder stop failed: $e');
    }
    _micStreamStarted = false;

    if (!_recorderDisposed) {
      try {
        await _recorder.dispose();
        _recorderDisposed = true;
        print('Recorder disposed');
      } catch (e) {
        print('Recorder dispose failed: $e');
      }
    }

    final path = await _writeSessionWavFile();
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording file was produced.')),
      );
      return;
    }

    print('Navigating to entry review');
    context.go(
      AppRoutes.entryReview,
      extra: EntryReviewExtra(
        showOnboardingProgress: true,
        recordingPath: path,
        transcript: _fullTranscript,
      ),
    );
  }

  Future<bool> _canStartRecording() async {
    var granted = await _recorder.hasPermission(request: false);
    if (!granted) {
      granted = await _recorder.hasPermission(request: true);
    }
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
      }
      return false;
    }

    const encoder = AudioEncoder.pcm16bits;
    final encoderSupported = await _recorder.isEncoderSupported(encoder);
    if (!encoderSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PCM streaming is not supported on this device.'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (_micStreamStarted || _sessionEnding) return;

    if (!await _canStartRecording()) return;

    try {
      const pcmConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _pcmSampleRate,
        numChannels: 1,
      );
      final stream = await _recorder.startStream(pcmConfig);
      _micStreamStarted = true;

      _micSessionSub = stream.listen(
        (chunk) {
          if (_sessionEnding) return;
          if (!_lhamoSpeaking) {
            _sessionPcm.add(chunk);
          }
          final dg = _deepgramSession;
          print(
            'Mic chunk received, awaitingUser=$_awaitingUserSpeech, '
            'dgNull=${dg == null}',
          );
          if (_awaitingUserSpeech && dg != null) {
            print('Feeding chunk to Deepgram');
            dg.addAudio(chunk);
          }
        },
        onError: (Object e, StackTrace st) {
          print('Mic stream error: $e\n$st');
        },
      );

      if (mounted) setState(() {});

    } catch (e) {
      print('Recording start failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopMicStreamSubscription() async {
    await _micSessionSub?.cancel();
    _micSessionSub = null;
    if (mounted) setState(() {});
  }

  Future<String?> _writeSessionWavFile() async {
    final pcm = _sessionPcm.takeBytes();
    if (pcm.isEmpty) return null;

    final wav = _pcmMono16LeWavBytes(Uint8List.fromList(pcm), _pcmSampleRate);
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/thankful_recordings');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final path =
        '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.wav';
    final f = File(path);
    await f.writeAsBytes(wav);
    return path;
  }

  Future<void> _onStopTapped() async {
    print('_onStopTapped (sessionEnding=$_sessionEnding mic=$_micStreamStarted)');
    await _closeSession(isEarly: true);
  }

  bool get _canTapStop => !_sessionEnding;

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    /// Locked crop in `Monk_Convo.svg`; zoom to full width (HTML monk uses full phone width).
    final faceWidth = screenW;

    /// HTML `.stop-btn` is 44×44. Burner PNGs include transparent margin around the pot — use a
    /// larger slot than the stop so the visible art reads closer to the control size.
    const stopExtent = 44.0;
    const incenseExtent = 150.0;

    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final safeTop = media.padding.top;
    /// Matches timer `Padding`: `screenTop` + bottom `6` + `heading2` line (19×1.3).
    const timerBlockH = AppSpacing.screenTop + 6.0 + 19.0 * 1.3;
    final monkH = faceWidth * (210 / 527);
    const vibrationSlot = 16.0 + 48.0 + 16.0;
    const listeningRowH = 24.0;
    final monkCenterFromClusterTop = monkH / 2;
    final clusterHeight = monkH + vibrationSlot + listeningRowH;
    final monkClusterTopPadRaw = screenH / 2 -
        safeTop -
        timerBlockH -
        monkCenterFromClusterTop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.screenTop,
                AppSpacing.screenH,
                6,
              ),
              child: Text(
                _formatTimer(_elapsedSeconds),
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxTop = math.max(
                    0.0,
                    constraints.maxHeight - clusterHeight,
                  );
                  final monkClusterTopPad =
                      monkClusterTopPadRaw.clamp(0.0, maxTop);
                  return Padding(
                    padding: EdgeInsets.only(top: monkClusterTopPad),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedBuilder(
                          animation: _breatheController,
                          builder: (context, _) {
                            /// Matches HTML `breathe`: ~3px drift, 5s ease-in-out (opacity dip subtle).
                            final curved = Curves.easeInOut
                                .transform(_breatheController.value);
                            final dy = -3.5 * curved;
                            final opacity = 1.0 - 0.03 * curved;
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, dy),
                                child: SizedBox(
                                  width: faceWidth,
                                  height: monkH,
                                  child: SvgPicture.asset(
                                    'assets/mascot/Monk_Convo.svg',
                                    width: faceWidth,
                                    height: monkH,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    allowDrawingOutsideViewBox: false,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: _VibrationString(convoState: _convoState),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: _ConvoStateLabel(
                            state: _convoState,
                            slowBlink: _slowBlinkController,
                            fastBlink: _blinkController,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: IgnorePointer(
                child: SizedBox(
                  width: incenseExtent,
                  height: incenseExtent,
                  child: AnimatedBuilder(
                    animation: _incenseController,
                    builder: (context, _) {
                      final first = _incenseController.value < 0.5;
                      return Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: first ? 1 : 0,
                            child: Image.asset(
                              'assets/mascot/incense_burner1.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          Opacity(
                            opacity: first ? 0 : 1,
                            child: Image.asset(
                              'assets/mascot/incense_burner2.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Center(
                child: Material(
                  color: _canTapStop ? AppColors.cta : AppColors.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _canTapStop ? _onStopTapped : null,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: stopExtent,
                      height: stopExtent,
                      child: const Center(
                        child: _StopIcon(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                6,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List _pcmMono16LeWavBytes(Uint8List pcmData, int sampleRate) {
  const numChannels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = pcmData.length;
  final riffChunkSize = 36 + dataSize;

  final out = Uint8List(44 + dataSize);
  var o = 0;
  void writeAscii(String s) {
    for (var i = 0; i < s.length; i++) {
      out[o++] = s.codeUnitAt(i);
    }
  }

  void writeLe32(int v) {
    out[o++] = v & 0xff;
    out[o++] = (v >> 8) & 0xff;
    out[o++] = (v >> 16) & 0xff;
    out[o++] = (v >> 24) & 0xff;
  }

  void writeLe16(int v) {
    out[o++] = v & 0xff;
    out[o++] = (v >> 8) & 0xff;
  }

  writeAscii('RIFF');
  writeLe32(riffChunkSize);
  writeAscii('WAVE');
  writeAscii('fmt ');
  writeLe32(16);
  writeLe16(1);
  writeLe16(numChannels);
  writeLe32(sampleRate);
  writeLe32(byteRate);
  writeLe16(blockAlign);
  writeLe16(bitsPerSample);
  writeAscii('data');
  writeLe32(dataSize);
  out.setRange(44, 44 + pcmData.length, pcmData);
  return out;
}

class _WaveMotion {
  const _WaveMotion({
    required this.amplitude,
    required this.harmonics,
    required this.periodMs,
  });

  final double amplitude;
  final double harmonics;
  final int periodMs;
}

_WaveMotion _waveMotionFor(ConvoState state) {
  switch (state) {
    case ConvoState.meditating:
      return const _WaveMotion(amplitude: 6, harmonics: 1, periodMs: 3000);
    case ConvoState.listening:
      return const _WaveMotion(amplitude: 10, harmonics: 2, periodMs: 1800);
    case ConvoState.speaking:
      return const _WaveMotion(amplitude: 16, harmonics: 3, periodMs: 900);
  }
}

class _VibrationString extends StatefulWidget {
  const _VibrationString({required this.convoState});

  final ConvoState convoState;

  @override
  State<_VibrationString> createState() => _VibrationStringState();
}

class _VibrationStringState extends State<_VibrationString>
    with TickerProviderStateMixin {
  static const double _height = 48;
  static const Duration _transitionDuration = Duration(milliseconds: 600);

  late final AnimationController _phaseController;
  late final AnimationController _transitionController;

  late _WaveMotion _fromMotion;
  late _WaveMotion _toMotion;

  @override
  void initState() {
    super.initState();
    _toMotion = _waveMotionFor(widget.convoState);
    _fromMotion = _toMotion;
    _phaseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _toMotion.periodMs),
    )..repeat();
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    )..value = 1;
  }

  @override
  void didUpdateWidget(_VibrationString oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.convoState != widget.convoState) {
      final t = _transitionController.value.clamp(0.0, 1.0);
      _fromMotion = _WaveMotion(
        amplitude: _lerp(_fromMotion.amplitude, _toMotion.amplitude, t),
        harmonics: _lerp(_fromMotion.harmonics, _toMotion.harmonics, t),
        periodMs: _toMotion.periodMs,
      );
      _toMotion = _waveMotionFor(widget.convoState);
      _phaseController.duration = Duration(milliseconds: _toMotion.periodMs);
      _transitionController
        ..reset()
        ..forward();
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _phaseController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_phaseController, _transitionController]),
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_transitionController.value);
          final amplitude = _lerp(_fromMotion.amplitude, _toMotion.amplitude, t);
          final harmonics =
              _lerp(_fromMotion.harmonics, _toMotion.harmonics, t);
          final phase = _phaseController.value * 2 * math.pi;
          return CustomPaint(
            painter: _VibrationStringPainter(
              amplitude: amplitude,
              harmonics: harmonics,
              phase: phase,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _VibrationStringPainter extends CustomPainter {
  _VibrationStringPainter({
    required this.amplitude,
    required this.harmonics,
    required this.phase,
  });

  final double amplitude;
  final double harmonics;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final midY = size.height / 2;
    final width = size.width;
    const steps = 120;

    for (var i = 0; i <= steps; i++) {
      final x = width * i / steps;
      final normalized = x / width;
      final y =
          midY + amplitude * math.sin(harmonics * math.pi * normalized + phase);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_VibrationStringPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.harmonics != harmonics ||
        oldDelegate.phase != phase;
  }
}

class _ConvoStateLabel extends StatelessWidget {
  const _ConvoStateLabel({
    required this.state,
    required this.slowBlink,
    required this.fastBlink,
  });

  final ConvoState state;
  final Animation<double> slowBlink;
  final Animation<double> fastBlink;

  String get _label {
    switch (state) {
      case ConvoState.meditating:
        return 'Meditating';
      case ConvoState.listening:
        return 'Listening';
      case ConvoState.speaking:
        return 'Speaking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.body.copyWith(
      color: AppColors.textTertiary,
    );

    if (state == ConvoState.speaking) {
      return Text(
        '$_label...',
        textAlign: TextAlign.center,
        style: textStyle,
      );
    }

    final blinkAnimation =
        state == ConvoState.meditating ? slowBlink : fastBlink;
    final delays = state == ConvoState.meditating
        ? const [0.0, 0.35, 0.7]
        : const [0.0, 0.22, 0.44];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_label, style: textStyle),
        const SizedBox(width: 3),
        ...List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _BlinkDot(
              animation: blinkAnimation,
              delaySec: delays[i],
            ),
          );
        }),
      ],
    );
  }
}

/// CSS `blink`: 0%,80%,100% opacity 0.2; 40% opacity 0.9.
class _BlinkDot extends StatelessWidget {
  const _BlinkDot({
    required this.animation,
    required this.delaySec,
  });

  final Animation<double> animation;
  final double delaySec;

  static double _blinkOpacity(double t) {
    final x = t % 1.0;
    if (x < 0.4) {
      return 0.2 + (0.9 - 0.2) * (x / 0.4);
    }
    if (x < 0.8) {
      return 0.9 - (0.9 - 0.2) * ((x - 0.4) / 0.4);
    }
    return 0.2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final shifted =
            (animation.value + delaySec / 1.4) % 1.0;
        return Opacity(
          opacity: _blinkOpacity(shifted),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// HTML stop control: 44×44 circle; inner icon 18×18 with 10×10 rounded square at 4,4.
class _StopIcon extends StatelessWidget {
  const _StopIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
