import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Home uses [watering] (`Monk_watering.png`) — bottom-centred, reference `screen8_home.html`.
enum MonkState {
  namaste,
  meditation,
  writing,
  watering,
  milestone,
  bowed,
}

class MonkMascot extends StatelessWidget {
  final MonkState state;
  final double width;

  /// When set, image scales to this height (`BoxFit.fitHeight`, width from aspect
  /// ratio) — matches HTML `height:100%;width:auto` in flex monk areas.
  /// Ignores [width] for layout.
  final double? layoutHeight;

  /// Mimics CSS `mix-blend-mode: multiply` with screen background ([AppColors.background]).
  /// Applied via [ColorFiltered] so decoding is not delegated to Image color APIs.
  final bool multiplyWithBackground;

  const MonkMascot({
    super.key,
    required this.state,
    this.width = 180,
    this.layoutHeight,
    this.multiplyWithBackground = false,
  });

  String get _assetPath {
    switch (state) {
      case MonkState.namaste:
        return 'assets/mascot/monk_namaste.png';
      case MonkState.meditation:
        return 'assets/mascot/Meditating_Monk.png';
      case MonkState.writing:
        return 'assets/mascot/Writing_monk.png';
      case MonkState.watering:
        return 'assets/mascot/Monk_watering.png';
      case MonkState.milestone:
        return 'assets/mascot/monk_milestone.png';
      case MonkState.bowed:
        return 'assets/mascot/monk_bowed.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    /// Downscale raster decode (~195 CSS px wide art) — helps large PNGs reliably decode.
    final cacheW = math.max(
      1,
      (width * dpr).round().clamp(200, 900),
    );

    Widget imageFromAsset({double? h, double? w}) {
      return Image.asset(
        _assetPath,
        width: h == null ? w : null,
        height: h,
        fit: h != null ? BoxFit.fitHeight : BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        cacheWidth: cacheW,
        errorBuilder: (_, error, _) {
          debugPrint('MonkMascot failed to load $_assetPath: $error');
          return SizedBox(
            width: w ?? width,
            height: h ?? w ?? width,
            child: const ColoredBox(color: AppColors.surfaceRaised),
          );
        },
      );
    }

    Widget core;
    if (layoutHeight != null) {
      final h = layoutHeight!;
      core = ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: imageFromAsset(h: h, w: width),
        ),
      );
    } else {
      core = imageFromAsset(w: width);
    }

    if (multiplyWithBackground) {
      core = ColorFiltered(
        colorFilter: ColorFilter.mode(
          AppColors.background,
          BlendMode.multiply,
        ),
        child: core,
      );
    }

    return core;
  }
}
