import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';

/// Live Deepgram session — WebSocket stays open until [DeepgramLiveSession.close].
class DeepgramLiveSession {
  DeepgramLiveSession._(
    this._channel,
    this._transcripts,
    this._socketSub,
  );

  final IOWebSocketChannel _channel;
  final StreamController<String> _transcripts;
  final StreamSubscription<dynamic> _socketSub;
  bool _isClosed = false;

  Stream<String> get transcriptStream => _transcripts.stream;

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
    if (!_transcripts.isClosed) {
      await _transcripts.close();
    }
    print('Deepgram session closed');
  }
}

/// Deepgram live transcription over WebSocket.
///
/// Requires `DEEPGRAM_API_KEY` in `.env` (loaded via [dotenv.load] at startup).
///
/// Use [startLiveSession] and push **linear16**, **16 kHz**, **mono** PCM via
/// [DeepgramLiveSession.addAudio]. Call [DeepgramLiveSession.close] when done.
class DeepgramService {
  const DeepgramService();

  static const _baseWss = 'wss://api.deepgram.com/v1/listen';

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
      '&interim_results=true&punctuate=true&endpointing=300',
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
    print('Deepgram WebSocket connected');

    final transcripts = StreamController<String>();
    final socketSub = channel.stream.listen(
      (message) {
        if (message is! String) return;
        final map = _tryParseJsonMap(message);
        if (map != null) {
          print('Deepgram message type: ${map['type']}');
        }
        final text = _transcriptFromDeepgramMessage(message);
        if (text != null && text.isNotEmpty && !transcripts.isClosed) {
          transcripts.add(text);
        }
      },
      onError: (Object e, StackTrace st) {
        print('Deepgram socket error: $e');
        if (!transcripts.isClosed) {
          transcripts.addError(e, st);
        }
      },
      onDone: () {
        print('Deepgram socket closed');
        if (!transcripts.isClosed) {
          unawaited(transcripts.close());
        }
      },
    );

    return DeepgramLiveSession._(channel, transcripts, socketSub);
  }
}

Map<String, dynamic>? _tryParseJsonMap(String message) {
  try {
    return jsonDecode(message) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? _transcriptFromDeepgramMessage(String message) {
  try {
    final map = jsonDecode(message) as Map<String, dynamic>;
    if (map['type'] != 'Results') return null;
    if (map['is_final'] != true && map['speech_final'] != true) return null;
    final ch = map['channel'];
    if (ch is! Map<String, dynamic>) return null;
    final alts = ch['alternatives'];
    if (alts is! List || alts.isEmpty) return null;
    final first = alts.first;
    if (first is! Map<String, dynamic>) return null;
    final transcript = first['transcript'];
    if (transcript is! String) return null;
    return transcript;
  } catch (_) {
    return null;
  }
}
