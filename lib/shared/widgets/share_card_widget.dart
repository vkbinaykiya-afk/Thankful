import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Off-screen share card (375×500) — matches `share_card.html`. Hardcoded tokens only.
class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({
    super.key,
    required this.quote,
    required this.tags,
    required this.userName,
    required this.dateLabel,
    this.showDownloadSection = false,
  });

  static const double cardWidth = 375;
  static const double cardHeight = 500;

  final String quote;
  final List<String> tags;
  final String userName;
  final String dateLabel;
  final bool showDownloadSection;

  static const Color _bg = Color(0xFFFAFAF8);
  static const Color _surface = Color(0xFFF0EDE6);
  static const Color _primary = Color(0xFF5E9A78);
  static const Color _textPrimary = Color(0xFF2C2416);
  static const Color _textJournal = Color(0xFF5C4A3A);
  static const Color _textSecondary = Color(0xFF7A7060);
  static const Color _textTertiary = Color(0xFFA89E8E);

  List<String> get _displayTags => tags
      .map((t) => t.trim())
      .where((s) => s.isNotEmpty)
      .take(3)
      .toList();

  TextStyle _text({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'Figtree',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print(
      '[ShareCardWidget] Built — quote: ${quote.length} chars, tags: ${tags.length}',
    );
    // ignore: avoid_print
    print('[ShareCardWidget] showDownloadSection: $showDownloadSection');

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: _bg,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Text(
                  'thankful',
                  textAlign: TextAlign.center,
                  style: _text(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: _primary,
                    height: 1.25,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_displayTags.isNotEmpty) ...[
                        Row(
                          children: [
                            for (var i = 0; i < _displayTags.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: _TagPill(
                                  label: _displayTags[i],
                                  textStyle: _text(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: _textSecondary,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        quote,
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: _textJournal,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 1,
                            color: _textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userName,
                            style: _text(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '·',
                            style: _text(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: _textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: _text(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (showDownloadSection)
                Container(
                color: _surface,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const CustomPaint(
                            painter: QrPlaceholderPainter(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan to download',
                          style: _text(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start journaling today',
                            style: _text(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              _PlatformRow(
                                icon: SvgPicture.string(
                                  _appleIconSvg,
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    _textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                label: 'Available on iOS',
                                textStyle: _text(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PlatformRow(
                                icon: SvgPicture.string(
                                  _googlePlayIconSvg,
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    _textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                label: 'Available on Android',
                                textStyle: _text(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _appleIconSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.54 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"/>
</svg>
''';

  static const String _googlePlayIconSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M22.018 13.298l-3.919 2.218-3.515-3.493 3.543-3.521 3.891 2.202a1.49 1.49 0 0 1 0 2.594zM1.337.924a1.486 1.486 0 0 0-.112.568v21a1.49 1.49 0 0 0 .227.787l11.285-11.36L1.337.924zm15.1 9.075L3.765 2.15 14.3 13.42 16.437 10zm-14.666 13l12.7-7.164-2.138-2.129L1.771 22z"/>
</svg>
''';
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.textStyle,
  });

  final String label;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ShareCardWidget._surface,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: textStyle,
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.icon,
    required this.label,
    required this.textStyle,
  });

  final Widget icon;
  final String label;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 16, height: 16, child: icon),
        const SizedBox(width: 8),
        Text(label, style: textStyle),
      ],
    );
  }
}

/// QR placeholder matching `share_card.html` 21×21 module grid.
class QrPlaceholderPainter extends CustomPainter {
  const QrPlaceholderPainter();

  static const Color _ink = Color(0xFF2C2416);
  static const Color _paper = Color(0xFFFAFAF8);

  /// All data-region rects from share_card.html (finders drawn separately).
  static const List<(int x, int y, int w, int h)> _dataRects = [
    (8, 6, 1, 1),
    (10, 6, 1, 1),
    (12, 6, 1, 1),
    (6, 8, 1, 1),
    (6, 10, 1, 1),
    (6, 12, 1, 1),
    (8, 8, 1, 1),
    (10, 9, 1, 1),
    (11, 8, 1, 1),
    (12, 9, 1, 1),
    (9, 10, 2, 1),
    (12, 10, 1, 1),
    (8, 11, 1, 2),
    (10, 11, 2, 2),
    (13, 11, 1, 1),
    (9, 13, 1, 1),
    (12, 12, 1, 2),
    (8, 14, 2, 1),
    (11, 14, 1, 2),
    (13, 15, 1, 1),
    (9, 16, 2, 1),
    (12, 16, 2, 1),
    (14, 8, 2, 1),
    (17, 8, 1, 1),
    (19, 8, 2, 1),
    (15, 9, 1, 2),
    (18, 9, 1, 1),
    (20, 9, 1, 2),
    (14, 11, 1, 2),
    (16, 10, 2, 1),
    (19, 11, 2, 1),
    (15, 12, 1, 2),
    (17, 12, 1, 1),
    (14, 14, 2, 1),
    (17, 13, 3, 1),
    (16, 14, 1, 2),
    (19, 14, 2, 1),
    (14, 16, 1, 1),
    (18, 15, 1, 2),
    (20, 16, 1, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 21;
    final unit = size.shortestSide / grid;
    final ink = Paint()..color = _ink;
    final paper = Paint()..color = _paper;

    void finder(int gx, int gy) {
      canvas.drawRect(
        Rect.fromLTWH(gx * unit, gy * unit, 7 * unit, 7 * unit),
        ink,
      );
      canvas.drawRect(
        Rect.fromLTWH((gx + 1) * unit, (gy + 1) * unit, 5 * unit, 5 * unit),
        paper,
      );
      canvas.drawRect(
        Rect.fromLTWH((gx + 2) * unit, (gy + 2) * unit, 3 * unit, 3 * unit),
        ink,
      );
    }

    finder(0, 0);
    finder(14, 0);
    finder(0, 14);

    for (final (x, y, w, h) in _dataRects) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QrPlaceholderPainter oldDelegate) => false;
}
