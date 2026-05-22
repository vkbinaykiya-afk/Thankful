import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Post-session conversation quality evals (proxy metrics + LLM judge). Non-blocking.
class ConversationEvalService {
  const ConversationEvalService();

  /// Runs all evals post-session. Call with [unawaited] — never block on this.
  Future<void> evaluate({
    required String sessionId,
    required String rawTranscript,
    required int exchangeCount,
    required bool completedNaturally,
    required String? highlightQuote,
  }) async {
    print('[Eval] Starting post-session eval | session: $sessionId');
    _logProxyMetrics(
      sessionId: sessionId,
      rawTranscript: rawTranscript,
      exchangeCount: exchangeCount,
      completedNaturally: completedNaturally,
      highlightQuote: highlightQuote,
    );
    await _runLlmJudge(
      sessionId: sessionId,
      rawTranscript: rawTranscript,
    );
  }

  void _logProxyMetrics({
    required String sessionId,
    required String rawTranscript,
    required int exchangeCount,
    required bool completedNaturally,
    required String? highlightQuote,
  }) {
    print('[EvalMetric] session: $sessionId | exchange_depth: $exchangeCount');
    print(
      '[EvalMetric] session: $sessionId | completed_naturally: $completedNaturally',
    );

    final hasQuote =
        highlightQuote != null && highlightQuote.trim().isNotEmpty;
    print(
      '[EvalMetric] session: $sessionId | highlight_quote_present: $hasQuote',
    );

    final lines = rawTranscript
        .split('\n')
        .where((l) => l.trim().startsWith('You:'))
        .toList();
    final wordCounts = lines.map((l) {
      final text = l.replaceFirst(RegExp(r'^You:\s*'), '');
      return text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
    }).toList();
    print(
      '[EvalMetric] session: $sessionId | user_word_counts_per_turn: $wordCounts',
    );

    if (wordCounts.length >= 2) {
      final increasing = wordCounts.last > wordCounts.first;
      print(
        '[EvalMetric] session: $sessionId | engagement_deepened: $increasing',
      );
    }
  }

  Future<void> _runLlmJudge({
    required String sessionId,
    required String rawTranscript,
  }) async {
    print('[EvalJudge] Running LLM-as-judge for session: $sessionId');
    try {
      if (!dotenv.isInitialized) return;
      final apiKey = dotenv.env['ANTHROPIC_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) return;

      const judgePrompt = '''
You are evaluating a voice journaling conversation between a user and Lhamo, a monk guide.

Evaluate the conversation on these dimensions. Respond ONLY with valid JSON, no markdown:
{
  "one_question_per_turn": true/false,
  "acknowledges_before_asking": true/false,
  "questioning_gets_more_specific": true/false,
  "tone_warm_not_saccharine": true/false,
  "nudges_toward_gratitude": true/false,
  "overall_quality": 1-5,
  "flags": ["list any issues found"]
}
      ''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 512,
          'system': judgePrompt,
          'messages': [
            {'role': 'user', 'content': 'Transcript:\n$rawTranscript'},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final content = decoded['content'];
        if (content is List && content.isNotEmpty) {
          final first = content.first;
          if (first is Map<String, dynamic> && first['text'] is String) {
            print('[EvalJudge] session: $sessionId | result: ${first['text']}');
          }
        }
      } else {
        print('[EvalJudge] API error: ${response.statusCode}');
      }
    } catch (e) {
      print('[EvalJudge] Failed silently: $e');
    }
  }
}
