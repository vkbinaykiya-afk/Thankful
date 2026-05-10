import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Live journal / conversation UI — matches `docs/reference/design_htmls/convo-screen.html`.
class OnboardingConvoScreen extends StatefulWidget {
  const OnboardingConvoScreen({super.key});

  @override
  State<OnboardingConvoScreen> createState() => _OnboardingConvoScreenState();
}

class _OnboardingConvoScreenState extends State<OnboardingConvoScreen>
    with TickerProviderStateMixin {
  static const List<double> _barHeights = [
    9, 16, 22, 24, 15, 12, 21, 18, 24, 14, 20, 10, 21, 15,
  ];

  static const List<double> _barDelaysSec = [
    0, 0.14, 0.28, 0.42, 0.56, 0.70, 0.84, 0.98,
    0.18, 0.36, 0.60, 0.80, 0.46, 0.66,
  ];

  Timer? _timer;
  int _elapsedSeconds = 0;

  late final AnimationController _waveController;
  late final Animation<double> _waveCurved;
  late final AnimationController _breatheController;
  late final AnimationController _blinkController;
  late final AnimationController _incenseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _waveCurved = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _incenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _breatheController.dispose();
    _blinkController.dispose();
    _incenseController.dispose();
    super.dispose();
  }

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
    /// Waveform row + pad below + gap; then monk center = half of monk slot.
    const waveSlot = 36.0 + 12.0 + 6.0;
    const listeningRowH = 24.0;
    const gapMonkListen = 6.0;
    final monkCenterFromClusterTop = waveSlot + monkH / 2;
    final clusterHeight =
        waveSlot + monkH + gapMonkListen + listeningRowH;
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedBuilder(
                              animation: _waveCurved,
                              builder: (context, _) {
                                return _ConvoWaveform(
                                  waveValue: _waveCurved.value,
                                  barHeights: _barHeights,
                                  barDelaysSec: _barDelaysSec,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Listening',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              ...List.generate(3, (i) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: _BlinkDot(
                                    animation: _blinkController,
                                    delaySec: [0.0, 0.22, 0.44][i],
                                  ),
                                );
                              }),
                            ],
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
                  color: AppColors.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.demo),
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

class _ConvoWaveform extends StatelessWidget {
  const _ConvoWaveform({
    required this.waveValue,
    required this.barHeights,
    required this.barDelaysSec,
  });

  final double waveValue;
  final List<double> barHeights;
  final List<double> barDelaysSec;

  static const double _periodSec = 2.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barHeights.length, (i) {
          final delay = barDelaysSec[i];
          var phase =
              (waveValue * _periodSec - delay) % _periodSec / _periodSec;
          if (phase < 0) phase += 1;
          final bump = math.sin(phase * math.pi);
          final scaleY = 0.25 + 0.75 * bump;
          final opacity = 0.45 + 0.55 * bump;
          final h = barHeights[i];
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4.0),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                alignment: Alignment.bottomCenter,
                scaleY: scaleY,
                child: Container(
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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
