class Question {
  final String id;
  final String text;
  final String type; // 'truth' or 'dare'
  final String category; // 'Vanilla', 'Playful', 'Wild', 'Extreme', 'Couple'

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.category,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'truth',
      category: json['category']?.toString() ?? 'Vanilla',
    );
  }

  Question copyWith({
    String? id,
    String? text,
    String? type,
    String? category,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }
}
