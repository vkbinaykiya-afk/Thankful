import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Cartesia Sonic TTS (`/tts/bytes`).
///
/// Requires `CARTESIA_API_KEY` in `.env` (loaded via [dotenv.load] at startup).
class CartesiaService {
  const CartesiaService();

  static const _endpoint = 'https://api.cartesia.ai/tts/bytes';
  static const _voiceId = 'a33f7a4c-100f-41cf-a1fd-5822e8fc253f';
  static const _modelId = 'sonic-2';
  static const _cartesiaVersion = '2026-03-01';

  String _requireCartesiaApiKey() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'flutter_dotenv is not initialized. Ensure dotenv.load() runs before '
        'calling CartesiaService.speak.',
      );
    }
    final raw = dotenv.env['CARTESIA_API_KEY'];
    final key = raw?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'CARTESIA_API_KEY is missing or empty in .env.',
      );
    }
    return key;
  }

  /// Synthesizes [text] to MP3 (44.1 kHz) and returns raw audio bytes.
  Future<Uint8List> speak(String text) async {
    final apiKey = _requireCartesiaApiKey();

    final payload = {
      'model_id': _modelId,
      'transcript': text,
      'voice': {
        'mode': 'id',
        'id': _voiceId,
      },
      'speed': -0.3,
      'output_format': {
        'container': 'mp3',
        'sample_rate': 44100,
        'bit_rate': 128000,
      },
    };

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Cartesia-Version': _cartesiaVersion,
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw StateError('Cartesia TTS request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cartesia TTS error ${response.statusCode}: ${response.body}',
      );
    }

    return Uint8List.fromList(response.bodyBytes);
  }
}
