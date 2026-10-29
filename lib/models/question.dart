import 'difficulty_level.dart';

class Question {
  final String id;
  final String type;
  final String text;
  final DifficultyLevel difficulty;

  Question({
    required this.id,
    required this.type,
    required this.text,
    this.difficulty = DifficultyLevel.playful,
  });

  Question copyWith({
    String? id,
    String? type,
    String? text,
    DifficultyLevel? difficulty,
  }) {
    return Question(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}
