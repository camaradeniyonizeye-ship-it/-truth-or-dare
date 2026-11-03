import 'package:flutter_test/flutter_test.dart';
import 'package:truth_or_dare/models/game_rules.dart';

void main() {
  group('GameRules.scoreAfterChallenge', () {
    test('awards completion points', () {
      expect(
        GameRules.scoreAfterChallenge(currentScore: 0, completed: true),
        GameRules.pointsForCompletion,
      );
    });

    test('deducts failure points from an existing score', () {
      expect(
        GameRules.scoreAfterChallenge(currentScore: 20, completed: false),
        20 - GameRules.pointsForFailure,
      );
    });

    test('never allows a negative score', () {
      expect(
        GameRules.scoreAfterChallenge(currentScore: 2, completed: false),
        0,
      );
    });
  });
}
