import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/widgets/share_card_widget.dart';

/// Captures [ShareCardWidget] off-screen and shares as PNG.
class ShareCardService {
  const ShareCardService();

  /// Flip to `true` when App Store / Play download links are ready.
  static const bool _showDownloadSection = false;

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

  static String formatShareDate(DateTime d) {
    final local = d.toLocal();
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String _resolveQuote(String? highlightQuote, String? summary) {
    final highlight = highlightQuote?.trim();
    if (highlight != null && highlight.isNotEmpty) return highlight;
    final sum = summary?.trim();
    if (sum != null && sum.isNotEmpty) return sum;
    return 'A quiet moment of reflection.';
  }

  static String _truncateQuote(String quote) {
    if (quote.length <= 160) return quote;
    return '${quote.substring(0, 157)}…';
  }

  Future<void> shareEntry({
    required BuildContext context,
    required String? highlightQuote,
    required String? summary,
    required List<String> tags,
    required String? mood,
    required String userName,
    required DateTime createdAt,
    Rect? sharePositionOrigin,
  }) async {
    var quote = _resolveQuote(highlightQuote, summary);
    // ignore: avoid_print
    print('[ShareCardService] quote resolved: $quote');
    quote = _truncateQuote(quote);

    final repaintKey = GlobalKey();
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: -(ShareCardWidget.cardWidth + 400),
        top: 0,
        child: RepaintBoundary(
          key: repaintKey,
          child: ShareCardWidget(
            quote: quote,
            tags: tags.take(3).toList(),
            userName: userName,
            dateLabel: formatShareDate(createdAt),
            showDownloadSection: _showDownloadSection,
          ),
        ),
      ),
    );

    if (!context.mounted) return;
    Overlay.of(context).insert(overlayEntry);
    // ignore: avoid_print
    print('[ShareCardService] Overlay inserted');

    try {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!context.mounted) return;

      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      // ignore: avoid_print
      print(
        '[ShareCardService] Render size: ${boundary?.size}',
      );
      if (boundary == null) return;

      try {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (byteData == null) {
          throw StateError('PNG byte data was null');
        }

        final bytes = byteData.buffer.asUint8List();
        // ignore: avoid_print
        print('[ShareCardService] PNG captured — ${bytes.length} bytes');

        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/thankful_share_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(path).writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(path, mimeType: 'image/png')],
          sharePositionOrigin: sharePositionOrigin,
        );
      } catch (e) {
        // ignore: avoid_print
        print('[ShareCardService] Share failed: $e');
        await Share.share(
          '"$quote"\n\n— thankful',
          sharePositionOrigin: sharePositionOrigin,
        );
      }
    } finally {
      overlayEntry.remove();
    }
  }
}
