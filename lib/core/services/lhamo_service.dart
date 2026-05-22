import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/convo_session_config.dart';
import '../constants/lhamo_openings.dart';
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

  /// Session opener — random line from [LhamoOpenings], no API call (avoids
  /// the model defaulting to the first example in the system prompt).
  String getSessionOpening() {
    final fullName = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['name']
            ?.toString() ??
        '';
    final firstName = fullName.split(' ').first.trim().isNotEmpty
        ? fullName.split(' ').first.trim()
        : 'friend';
    final opening = LhamoOpenings.pick(firstName);
    print('[Lhamo] session opening: $opening');
    return opening;
  }

  /// Calls Claude with session [history] (maps with `role` and `content` keys),
  /// the latest [userMessage], [exchangeCount], and [isClosing].
  Future<String> getResponse({
    required List<Map<String, String>> history,
    required String userMessage,
    required int exchangeCount,
    required bool isClosing,
  }) async {
    final fullName = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['name']
            ?.toString() ??
        '';
    final firstName = fullName.split(' ').first.trim().isNotEmpty
        ? fullName.split(' ').first.trim()
        : 'friend';
    print('[Lhamo] firstName: $firstName');

    final memoryBlock = '';

    const sessionId = '';

    final userWordCount = userMessage
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final isGratitudeTurn =
        !isClosing && exchangeCount == ConvoSessionConfig.gratitudeTurnExchangeCount;
    final isFinalTurn =
        !isClosing && exchangeCount >= ConvoSessionConfig.finalTurnExchangeCount;

    print(
      '[EvalMetric] turn: $exchangeCount | user_word_count: $userWordCount | session_id: $sessionId | gratitude_turn: $isGratitudeTurn | final_turn: $isFinalTurn',
    );

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

    final gratitudeTurnBlock = isGratitudeTurn
        ? '''

GRATITUDE TURN (mandatory): Help them name what is good — this is a gratitude journal. After a brief land on what they shared, ask exactly ONE question that invites something they are grateful for today (a person, moment, feeling, or small gift). Not yes/no. Examples: "What feels like a gift you want to keep from today, $firstName?" "What are you grateful for right now?" "Who or what showed up for you today?"'''
        : '';

    final finalTurnBlock = isFinalTurn
        ? '''

FINAL TURN (mandatory): They just named what they are grateful for. LAND that warmly, REFRAME gently — weave the thread of the session. One or two sentences. No question. No question mark. Do not open anything new.'''
        : '';

    final contextual = '''
USER CONTEXT:
- first_name: $firstName
- exchange_count: $exchangeCount
- memory_block: $memoryBlock
- is_closing: $isClosing
- gratitude_turn: $isGratitudeTurn
- final_turn: $isFinalTurn$gratitudeTurnBlock$finalTurnBlock

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

    late http.Response httpResponse;
    try {
      httpResponse = await http.post(
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

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      throw StateError(
        'Anthropic API error ${httpResponse.statusCode}: ${httpResponse.body}',
      );
    }

    final decoded = jsonDecode(httpResponse.body) as Map<String, dynamic>;
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

    final response = buffer.toString();
    final questionCount = response.split('?').length - 1;
    print(
      '[EvalMetric] lhamo_question_count: $questionCount | expected: 1 | response_preview: ${response.substring(0, response.length.clamp(0, 80))}',
    );
    if (!isClosing && !isFinalTurn && questionCount != 1) {
      print(
        '[EvalWarning] Lhamo asked $questionCount questions — expected exactly 1',
      );
    }
    if (isFinalTurn && questionCount > 0) {
      print(
        '[EvalWarning] Final turn included $questionCount question(s) — expected 0',
      );
    }

    return response;
  }
}
