import '../models/player.dart';

class QuestionLoader {
  static String processQuestionText(
      String rawText, Player? currentPlayer, List<Player> allPlayers) {
    if (currentPlayer == null) return rawText;

    String processed = rawText.replaceAll('{player}', currentPlayer.name);

    if (processed.contains('{target}') || processed.contains('{partner}')) {
      // Enforce opposite gender matching (Boy to Girl or Girl to Boy)
      final oppositeGender = currentPlayer.gender == 'Male' ? 'Female' : 'Male';
      final potentialTargets = allPlayers
          .where((p) => p.id != currentPlayer.id && p.gender == oppositeGender)
          .toList();

      // Fallback to any other player if no opposite gender is present in the group
      final targetPool = potentialTargets.isNotEmpty
          ? potentialTargets
          : allPlayers.where((p) => p.id != currentPlayer.id).toList();

      if (targetPool.isNotEmpty) {
        final target = targetPool[DateTime.now().millisecondsSinceEpoch % targetPool.length];
        processed = processed
            .replaceAll('{target}', target.name)
            .replaceAll('{partner}', target.name);
      } else {
        processed = processed
            .replaceAll('{target}', 'someone')
            .replaceAll('{partner}', 'someone');
      }
    }

    return processed;
  }
}
