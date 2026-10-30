class Question {
  final String id;
  final String type; // 'truth' or 'dare'
  final String text;
  final String category; // 'Vanilla', 'Playful', 'Wild', 'Extreme', 'Couple'

  Question({
    required this.id,
    required this.type,
    required this.text,
    required this.category,
  });

  // Getter so any code calling q.difficulty gets the category seamlessly
  String get difficulty => category;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'truth',
      text: json['text']?.toString() ?? '',
      category: json['category'] ?? json['difficulty']?.toString() ?? 'Vanilla',
    );
  }

  Question copyWith({
    String? id,
    String? type,
    String? text,
    String? category,
  }) {
    return Question(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      category: category ?? this.category,
    );
  }
}
