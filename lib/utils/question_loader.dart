import '../models/player.dart';
import '../data/game_data.dart';

class QuestionLoader {
  /// Loads questions supporting positional language key, async calls, and rule checks.
  static Future<List<String>> loadQuestions(
    String langKey, {
    String category = 'vanilla',
    String type = 'truth',
    Player? currentPlayer,
    String otherPlayer = 'Someone',
  }) async {
    // 1. Normalize language key to match GameData keys ('en', 'fr', 'rw', 'es')
    String normalizedLang = 'en';
    String lowerKey = langKey.toLowerCase();

    if (lowerKey.contains('fr')) {
      normalizedLang = 'fr';
    } else if (lowerKey.contains('rw') || lowerKey.contains('kinyarwanda')) {
      normalizedLang = 'rw';
    } else if (lowerKey.contains('es') || lowerKey.contains('spanish')) {
      normalizedLang = 'es';
    } else if (lowerKey.contains('en') || lowerKey.contains('english')) {
      normalizedLang = 'en';
    }

    String chosenType = type.toLowerCase();

    // 2. Rule Enforcement: No choosing Truth twice continuously
    if (currentPlayer != null) {
      if (chosenType == 'truth' && currentPlayer.lastChoice?.toLowerCase() == 'truth') {
        throw Exception("${currentPlayer.name} cannot choose Truth twice in a row! Please pick Dare.");
      }
      currentPlayer.lastChoice = chosenType;
    }

    String playerName = currentPlayer?.name ?? 'Player';
    String partnerName = currentPlayer?.partner?.name ?? 'Partner';

    // 3. Fetch questions from GameData cache with placeholders injected
    return GameData.getQuestions(
      normalizedLang,
      category.toLowerCase(),
      chosenType,
      playerName: playerName,
      partnerName: partnerName,
      otherPlayer: otherPlayer,
    );
  }

  /// Processes text placeholders ({name}, {partner}, {other_player}) for individual questions.
  static String processQuestionText(
    String text, {
    required Player currentPlayer,
    String otherPlayer = 'Someone',
  }) {
    String partnerName = currentPlayer.partner?.name ?? 'Partner';
    return text
        .replaceAll('{name}', currentPlayer.name)
        .replaceAll('{partner}', partnerName)
        .replaceAll('{other_player}', otherPlayer);
  }
}
