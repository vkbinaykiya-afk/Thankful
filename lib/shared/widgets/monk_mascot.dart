import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum MonkState { namaste, meditation, writing, milestone, bowed }

class MonkMascot extends StatelessWidget {
  final MonkState state;
  final double width;

  /// When set, image scales to this height (`BoxFit.fitHeight`, width from aspect
  /// ratio) — matches HTML `height:100%;width:auto` in flex monk areas.
  /// Ignores [width] for layout.
  final double? layoutHeight;

  /// Knocks out harsh white in raster edges by multiplying with [AppColors.background]
  /// (same intent as `mix-blend-mode: multiply` in reference HTML).
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
      case MonkState.milestone:
        return 'assets/mascot/monk_milestone.png';
      case MonkState.bowed:
        return 'assets/mascot/monk_bowed.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = multiplyWithBackground ? AppColors.background : null;
    final blend =
        multiplyWithBackground ? BlendMode.multiply : null;

    if (layoutHeight != null) {
      final h = layoutHeight!;
      final image = Image.asset(
        _assetPath,
        height: h,
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        color: color,
        colorBlendMode: blend,
        errorBuilder: (_, _, _) => SizedBox(
          height: h,
          width: h,
          child: ColoredBox(color: AppColors.surfaceRaised),
        ),
      );
      return ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: image,
        ),
      );
    }

    return Image.asset(
      _assetPath,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      color: color,
      colorBlendMode: blend,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: width,
        child: ColoredBox(color: AppColors.surfaceRaised),
      ),
    );
  }
}
