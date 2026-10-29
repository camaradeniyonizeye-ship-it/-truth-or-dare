import 'question.dart';
import 'player.dart';

class GameState {
  final List<Player> players;
  final List<Question> questions;
  final List<Question> usedQuestions;
  final int currentPlayerIndex;
  final int currentQuestionIndex;
  final String currentType;

  GameState({
    this.players = const [],
    this.questions = const [],
    this.usedQuestions = const [],
    this.currentPlayerIndex = 0,
    this.currentQuestionIndex = 0,
    this.currentType = '',
  });

  GameState copyWith({
    List<Player>? players,
    List<Question>? questions,
    List<Question>? usedQuestions,
    int? currentPlayerIndex,
    int? currentQuestionIndex,
    String? currentType,
  }) {
    return GameState(
      players: players ?? this.players,
      questions: questions ?? this.questions,
      usedQuestions: usedQuestions ?? this.usedQuestions,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentType: currentType ?? this.currentType,
    );
  }

  Player? getCurrentPlayer() =>
      currentPlayerIndex >= 0 && currentPlayerIndex < players.length
          ? players[currentPlayerIndex]
          : null;

  Question? getCurrentQuestion() =>
      currentQuestionIndex >= 0 && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  List<Player> getSortedPlayers() {
    final s = [...players];
    s.sort((a, b) => b.score.compareTo(a.score));
    return s;
  }

  Player? getWinner() => players.isEmpty ? null : getSortedPlayers().first;
}
