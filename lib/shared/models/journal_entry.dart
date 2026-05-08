class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final String? sessionTranscript;
  final DateTime createdAt;
  final DateTime sessionDate;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.sessionTranscript,
    required this.createdAt,
    required this.sessionDate,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        content: json['content'] as String,
        sessionTranscript: json['session_transcript'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        sessionDate: DateTime.parse(json['session_date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'session_transcript': sessionTranscript,
        'created_at': createdAt.toIso8601String(),
        'session_date': sessionDate.toIso8601String(),
      };
}
