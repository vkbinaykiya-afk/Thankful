import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';

/// Live Deepgram events for a user speaking turn.
///
/// [segmentFinal] — one finalized phrase chunk (user may still be talking).
/// [utteranceEnd] — Deepgram detected a long enough gap; [text] is the full turn.
class DeepgramListenEvent {
  const DeepgramListenEvent._({
    required this.text,
    required this.isUtteranceEnd,
  });

  const DeepgramListenEvent.segmentFinal(String text)
      : this._(text: text, isUtteranceEnd: false);

  const DeepgramListenEvent.utteranceEnd(String text)
      : this._(text: text, isUtteranceEnd: true);

  final String text;
  final bool isUtteranceEnd;
}

/// Live Deepgram session — WebSocket stays open until [DeepgramLiveSession.close].
class DeepgramLiveSession {
  DeepgramLiveSession._(
    this._channel,
    this._events,
    this._socketSub,
  );

  final IOWebSocketChannel _channel;
  final StreamController<DeepgramListenEvent> _events;
  final StreamSubscription<dynamic> _socketSub;
  bool _isClosed = false;

  Stream<DeepgramListenEvent> get listenStream => _events.stream;

  void addAudio(Uint8List chunk) {
    if (_isClosed) return;
    _channel.sink.add(chunk);
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    try {
      _channel.sink.add(jsonEncode({'type': 'CloseStream'}));
    } catch (_) {}
    try {
      await _channel.sink.close();
    } catch (_) {}
    await _socketSub.cancel();
    if (!_events.isClosed) {
      await _events.close();
    }
    print('Deepgram session closed');
  }
}

/// Deepgram live transcription over WebSocket.
///
/// Requires `DEEPGRAM_API_KEY` in `.env` (loaded via [dotenv.load] at startup).
///
/// End-of-turn uses [utterance_end_ms] (not phrase-level `speech_final` alone).
/// [endpointing] controls phrase boundaries while the user is still speaking.
///
/// Use [startLiveSession] and push **linear16**, **16 kHz**, **mono** PCM via
/// [DeepgramLiveSession.addAudio]. Call [DeepgramLiveSession.close] when done.
class DeepgramService {
  const DeepgramService();

  static const _baseWss = 'wss://api.deepgram.com/v1/listen';

  /// Silence before Deepgram closes a phrase (ms).
  static const endpointingMs = 1000;

  /// Gap after the last word before an [DeepgramListenEvent.utteranceEnd] (ms).
  static const utteranceEndMs = 1000;

  String _requireDeepgramApiKey() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'flutter_dotenv is not initialized. Ensure dotenv.load() runs before '
        'calling DeepgramService.startLiveSession.',
      );
    }
    final raw = dotenv.env['DEEPGRAM_API_KEY'];
    final key = raw?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'DEEPGRAM_API_KEY is missing or empty in .env.',
      );
    }
    return key;
  }

  /// Opens a live Deepgram socket; remains open until [DeepgramLiveSession.close].
  Future<DeepgramLiveSession> startLiveSession() async {
    final key = _requireDeepgramApiKey();
    final uri = Uri.parse(
      '$_baseWss?model=nova-2&encoding=linear16&sample_rate=16000&channels=1'
      '&interim_results=true&punctuate=true'
      '&endpointing=$endpointingMs'
      '&utterance_end_ms=$utteranceEndMs',
    );

    late final IOWebSocketChannel channel;
    try {
      channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Token $key'},
      );
    } catch (e, st) {
      print('Deepgram connection failed: $e\n$st');
      rethrow;
    }
    print(
      'Deepgram WebSocket connected '
      '(endpointing=${endpointingMs}ms, utterance_end=${utteranceEndMs}ms)',
    );

    final events = StreamController<DeepgramListenEvent>();
    final accumulated = StringBuffer();

    final socketSub = channel.stream.listen(
      (message) {
        if (message is! String) return;
        final map = _tryParseJsonMap(message);
        if (map == null) return;

        final type = map['type'];
        if (type == 'UtteranceEnd') {
          final lastWordEnd = map['last_word_end'];
          if (lastWordEnd is num && lastWordEnd < 0) {
            print('Deepgram UtteranceEnd ignored (already finalized)');
            return;
          }
          final full = accumulated.toString().trim();
          accumulated.clear();
          if (full.isNotEmpty && !events.isClosed) {
            print('Deepgram utterance end: $full');
            events.add(DeepgramListenEvent.utteranceEnd(full));
          }
          return;
        }

        if (type != 'Results' || map['is_final'] != true) return;

        final text = _transcriptTextFromResults(map);
        if (text == null || text.isEmpty) return;

        accumulated.write(text);
        accumulated.write(' ');
        if (!events.isClosed) {
          events.add(DeepgramListenEvent.segmentFinal(text));
        }
      },
      onError: (Object e, StackTrace st) {
        print('Deepgram socket error: $e');
        if (!events.isClosed) {
          events.addError(e, st);
        }
      },
      onDone: () {
        print('Deepgram socket closed');
        if (!events.isClosed) {
          unawaited(events.close());
        }
      },
    );

    return DeepgramLiveSession._(channel, events, socketSub);
  }
}

Map<String, dynamic>? _tryParseJsonMap(String message) {
  try {
    return jsonDecode(message) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? _transcriptTextFromResults(Map<String, dynamic> map) {
  final ch = map['channel'];
  if (ch is! Map<String, dynamic>) return null;
  final alts = ch['alternatives'];
  if (alts is! List || alts.isEmpty) return null;
  final first = alts.first;
  if (first is! Map<String, dynamic>) return null;
  final transcript = first['transcript'];
  if (transcript is! String) return null;
  return transcript;
}
