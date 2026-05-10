import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum MonkState { namaste, meditation, writing, milestone, bowed }

class MonkMascot extends StatelessWidget {
  final MonkState state;
  final double width;

  const MonkMascot({
    super.key,
    required this.state,
    this.width = 180,
  });

  String get _assetPath {
    switch (state) {
      case MonkState.namaste:
        return 'assets/mascot/monk_namaste.png';
      case MonkState.meditation:
        return 'assets/mascot/monk_meditation.png';
      case MonkState.writing:
        return 'assets/mascot/monk_writing.png';
      case MonkState.milestone:
        return 'assets/mascot/monk_milestone.png';
      case MonkState.bowed:
        return 'assets/mascot/monk_bowed.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: width,
        child: ColoredBox(color: AppColors.surfaceRaised),
      ),
    );
  }
}
