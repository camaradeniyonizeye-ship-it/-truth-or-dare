/// Shared scoring and timer values used throughout the game.
class GameRules {
  GameRules._();

  static const int pointsForCompletion = 10;
  static const int pointsForFailure = 5;
  static const int dareDurationSeconds = 15;

  /// Apply a challenge result while keeping scores at zero or above.
  static int scoreAfterChallenge({
    required int currentScore,
    required bool completed,
  }) {
    final delta = completed ? pointsForCompletion : -pointsForFailure;
    return (currentScore + delta).clamp(0, 0x7fffffff);
  }
}
