import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EntryEnrichment {
  const EntryEnrichment({
    required this.title,
    required this.tags,
    required this.summary,
    required this.highlightQuote,
    required this.mood,
    required this.formattedTranscript,
  });

  final String title;
  final List<String> tags;
  final String summary;
  final String? highlightQuote;
  final String mood;
  final String formattedTranscript;

  factory EntryEnrichment.fromJson(
    Map<String, dynamic> json, {
    required String rawTranscriptFallback,
  }) {
    final tagsRaw = json['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is String && t.trim().isNotEmpty) {
          tags.add(t.trim());
        }
      }
    }

    final quote = json['highlight_quote'];
    return EntryEnrichment(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'A Quiet Moment',
      tags: tags,
      summary: (json['summary'] as String?)?.trim().isNotEmpty == true
          ? (json['summary'] as String).trim()
          : 'Sometimes just showing up is enough.',
      highlightQuote: quote is String && quote.trim().isNotEmpty
          ? quote.trim()
          : null,
      mood: (json['mood'] as String?)?.trim().isNotEmpty == true
          ? (json['mood'] as String).trim()
          : 'Peaceful',
      formattedTranscript:
          (json['formatted_transcript'] as String?)?.trim().isNotEmpty == true
              ? (json['formatted_transcript'] as String).trim()
              : rawTranscriptFallback,
    );
  }

  static EntryEnrichment quietMomentFallback(String rawTranscript) {
    return EntryEnrichment(
      title: 'A Quiet Moment',
      tags: const [],
      summary: 'Sometimes just showing up is enough.',
      highlightQuote: null,
      mood: 'Peaceful',
      formattedTranscript: rawTranscript,
    );
  }
}

/// Enriches a session transcript via Claude (title, tags, summary, mood, etc.).
class EntryEnrichmentService {
  const EntryEnrichmentService();

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-5';
  static const _systemPrompt =
      'You are a journaling assistant. Analyze the conversation transcript '
      'and return a JSON object only. No preamble, no markdown, just valid JSON.';

  static const _userInstructions = '''
Analyze this conversation transcript and return JSON only with this shape:
{
  "title": "short evocative title, max 6 words",
  "tags": ["tag1", "tag2", "tag3"],
  "summary": "2 sentence warm summary of what was reflected on",
  "highlight_quote": "the single most resonant sentence the user said, or null",
  "mood": "one of: Grateful / Reflective / Peaceful / Heavy / Hopeful",
  "formatted_transcript": "Clean up the transcript keeping Lhamo: and You: speaker labels. On You: lines only, wrap 2-3 emotionally significant words or short phrases in **double asterisks** — example: You: I felt **completely lost** but also **grateful** somehow. Never add asterisks to Lhamo: lines. Always include asterisks on at least one You: line. This is mandatory."
}

Tags should be 2-3 emotional themes or meaningful topics from the reflection, not keywords. Examples: Gratitude, Letting Go, Family, Growth.

Transcript:
''';

  String _requireAnthropicApiKey() {
    if (!dotenv.isInitialized) {
      throw StateError(
        'flutter_dotenv is not initialized. Ensure dotenv.load() runs before '
        'calling EntryEnrichmentService.enrich.',
      );
    }
    final key = dotenv.env['ANTHROPIC_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw StateError('ANTHROPIC_API_KEY is missing or empty in .env.');
    }
    return key;
  }

  static bool _needsFallback(String rawTranscript) {
    if (!rawTranscript.contains('You:')) return true;
    final userText = _extractUserContent(rawTranscript);
    final wordCount = userText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return wordCount < 5;
  }

  static String _extractUserContent(String rawTranscript) {
    final buffer = StringBuffer();
    for (final line in rawTranscript.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('You:')) {
        buffer.writeln(trimmed.substring(4).trim());
      }
    }
    return buffer.toString().trim();
  }

  static String _extractJsonPayload(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      final lines = t.split('\n');
      if (lines.length >= 2) {
        final end = lines.last.trim() == '```' ? lines.length - 1 : lines.length;
        t = lines.sublist(1, end).join('\n').trim();
      }
    }
    return t;
  }

  Future<EntryEnrichment> enrich(String rawTranscript) async {
    final raw = rawTranscript.trim();
    if (raw.isEmpty || _needsFallback(raw)) {
      return EntryEnrichment.quietMomentFallback(rawTranscript);
    }

    final apiKey = _requireAnthropicApiKey();
    final body = <String, dynamic>{
      'model': _model,
      'max_tokens': 1024,
      'system': _systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': '$_userInstructions$raw',
        },
      ],
    };

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
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

    final jsonText = _extractJsonPayload(buffer.toString());
    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    final enrichment = EntryEnrichment.fromJson(
      parsed,
      rawTranscriptFallback: rawTranscript,
    );
    print('Enrichment result: ${enrichment.formattedTranscript}');
    return enrichment;
  }
}
