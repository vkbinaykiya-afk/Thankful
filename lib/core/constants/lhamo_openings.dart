import 'dart:math';

/// Opening questions for Lhamo — picked in-app so sessions do not repeat the same line.
class LhamoOpenings {
  LhamoOpenings._();

  static final _random = Random();

  static const List<String> _templates = [
    "What's been sitting with you today, [name]?",
    'What moment from today are you still holding onto?',
    'What did today ask of you, [name]?',
    'What are you still carrying from today?',
    "What showed up today that you weren't expecting?",
    'What felt heavy today, even a little?',
    "What's quietly on your mind right now, [name]?",
    'If today had a colour, what would it be?',
    "What's one thing today that made you pause, [name]?",
    'What did today feel like in your body?',
    'What surprised you today — even something small?',
    "What's one thing that happened today you want to remember?",
    'If today were a weather, what kind would it be?',
    'What are you feeling grateful for today, [name]?',
    'What went quietly right today?',
    'Who or what held you today, even a little?',
    'What moment today felt like a small gift?',
    'What do you want to set down before you sleep, [name]?',
    "What's something from today worth keeping?",
    'What does your heart need to say before the day closes?',
  ];

  /// Substitutes [name] for `[name]` in a randomly chosen template.
  static String pick(String name) {
    final displayName = name.trim().isEmpty ? 'friend' : name.trim();
    final template = _templates[_random.nextInt(_templates.length)];
    return template.replaceAll('[name]', displayName);
  }
}
