import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// OpenAI Whisper transcription. Requires `OPENAI_API_KEY` in `.env` (loaded via
/// [dotenv.load] in app startup).
class TranscriptionService {
  const TranscriptionService();

  static const _endpoint = 'https://api.openai.com/v1/audio/transcriptions';
  static const _model = 'whisper-1';

  String _requireOpenAiApiKey() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'flutter_dotenv is not initialized. Ensure dotenv.load() runs before '
        'calling transcribeAudio.',
      );
    }
    final raw = dotenv.env['OPENAI_API_KEY'];
    final key = raw?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing or empty in .env. Add your OpenAI API key '
        'to use Whisper transcription.',
      );
    }
    return key;
  }

  /// Sends [filePath] to OpenAI Whisper and returns the transcript text.
  ///
  /// Uses `model=whisper-1` at OpenAI `v1/audio/transcriptions`. Throws [ArgumentError] if the file
  /// is missing, [StateError] for configuration or API failures.
  Future<String> transcribeAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'No audio file exists at this path.',
      );
    }

    final apiKey = _requireOpenAiApiKey();

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = _model;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException(
          'Whisper API request timed out after 5 minutes.',
        ),
      );
    } on TimeoutException {
      rethrow;
    } on SocketException catch (e) {
      throw StateError(
        'Network error while contacting Whisper API: ${e.message}',
      );
    } catch (e) {
      throw StateError('Failed to send audio to Whisper API: $e');
    }

    late http.Response response;
    try {
      response = await http.Response.fromStream(streamed).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException(
          'Reading Whisper API response timed out after 2 minutes.',
        ),
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw StateError('Failed to read Whisper API response: $e');
    }

    if (response.statusCode != 200) {
      var detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final err = decoded['error'];
          if (err is Map<String, dynamic>) {
            final msg = err['message'];
            if (msg != null) detail = msg.toString();
          }
        }
      } catch (_) {
        // keep raw body as detail
      }
      throw StateError(
        'Whisper API request failed with HTTP ${response.statusCode}: $detail',
      );
    }

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object');
      }
      json = decoded;
    } catch (e) {
      throw StateError(
        'Whisper API returned invalid JSON (status ${response.statusCode}): $e',
      );
    }

    final text = json['text'];
    if (text is! String) {
      throw StateError(
        'Whisper API response missing a string "text" field: ${response.body}',
      );
    }
    if (text.isEmpty) {
      throw StateError('Whisper API returned an empty transcript.');
    }
    return text;
  }
}
