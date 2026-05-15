import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../constants/monk_prompt.dart';

/// Claude (Anthropic Messages API) for Lhamo voice session replies.
///
/// Requires `ANTHROPIC_API_KEY` in `.env` (loaded via [dotenv.load] at startup).
class LhamoService {
  const LhamoService();

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-5';

  String _requireAnthropicApiKey() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'flutter_dotenv is not initialized. Ensure dotenv.load() runs before '
        'calling LhamoService.getResponse.',
      );
    }
    final raw = dotenv.env['ANTHROPIC_API_KEY'];
    final key = raw?.trim();
    if (key == null || key.isEmpty) {
      throw StateError(
        'ANTHROPIC_API_KEY is missing or empty in .env.',
      );
    }
    return key;
  }

  /// Calls Claude with session [history] (maps with `role` and `content` keys),
  /// the latest [userMessage], [exchangeCount], and [isClosing].
  Future<String> getResponse({
    required List<Map<String, String>> history,
    required String userMessage,
    required int exchangeCount,
    required bool isClosing,
  }) async {
    final apiKey = _requireAnthropicApiKey();

    final messages = <Map<String, dynamic>>[];
    for (final m in history) {
      final role = (m['role'] ?? '').trim();
      final content = m['content'] ?? '';
      if (role != 'user' && role != 'assistant') continue;
      messages.add({
        'role': role,
        'content': content,
      });
    }

    final contextual = '''
<turn_context>
exchange_count: $exchangeCount
is_closing: $isClosing
</turn_context>

$userMessage''';
    messages.add({'role': 'user', 'content': contextual});

    final body = <String, dynamic>{
      'model': _model,
      'max_tokens': 1024,
      'system': [
        {
          'type': 'text',
          'text': lhamoMonkSystemPrompt,
          'cache_control': {'type': 'ephemeral'},
        },
      ],
      'messages': messages,
    };

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-beta': 'prompt-caching-2024-07-31',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw StateError('Anthropic API request failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'];
    if (content is! List) {
      throw StateError('Unexpected Anthropic response shape: missing content.');
    }

    final buffer = StringBuffer();
    for (final block in content) {
      if (block is! Map<String, dynamic>) continue;
      if (block['type'] != 'text') continue;
      final text = block['text'];
      if (text is String && text.isNotEmpty) {
        buffer.write(text);
      }
    }

    return buffer.toString();
  }
}
