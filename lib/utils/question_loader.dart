import '../models/player.dart';
import '../models/question.dart';
import '../data/game_data.dart';

class QuestionLoader {
  // Internal tracking maps to enforce rules without modifying player.dart
  static final Map<Player, String> _lastChoices = {};
  static final Map<Player, Player> _partners = {};

  static void assignPartner(Player player, Player partner) {
    _partners[player] = partner;
  }

  /// Loads questions and returns List<Question> as required by difficulty selection screen.
  static Future<List<Question>> loadQuestions(
    String langKey, {
    String category = 'vanilla',
    String type = 'truth',
    Player? currentPlayer,
    String otherPlayer = 'Someone',
  }) async {
    // 1. Normalize language key ('en', 'fr', 'rw', 'es')
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
      String? previousChoice = _lastChoices[currentPlayer];
      if (chosenType == 'truth' && previousChoice?.toLowerCase() == 'truth') {
        throw Exception("${currentPlayer.name} cannot choose Truth twice in a row! Please pick Dare.");
      }
      _lastChoices[currentPlayer] = chosenType;
    }

    String playerName = currentPlayer?.name ?? 'Player';
    Player? partnerObj = currentPlayer != null ? _partners[currentPlayer] : null;
    String partnerName = partnerObj?.name ?? 'Partner';

    // 3. Fetch raw strings from GameData cache
    List<String> rawStrings = GameData.getQuestions(
      normalizedLang,
      category.toLowerCase(),
      chosenType,
      playerName: playerName,
      partnerName: partnerName,
      otherPlayer: otherPlayer,
    );

    // 4. Map strings to Question objects with placeholders replaced
    return rawStrings.map((qText) {
      String processed = qText
          .replaceAll('{name}', playerName)
          .replaceAll('{partner}', partnerName)
          .replaceAll('{other_player}', otherPlayer);
      
      // Instantiates your model (change to Question(processed) if your constructor is positional)
      return Question(text: processed);
    }).toList();
  }

  /// Processes text placeholders supporting positional arguments matching game_screen.dart calls.
  static String processQuestionText(
    String text, [
    Player? currentPlayer,
    String otherPlayer = 'Someone',
  ]) {
    String partnerName = (currentPlayer != null ? _partners[currentPlayer]?.name : null) ?? 'Partner';
    String playerName = currentPlayer?.name ?? 'Player';
    
    return text
        .replaceAll('{name}', playerName)
        .replaceAll('{partner}', partnerName)
        .replaceAll('{other_player}', otherPlayer);
  }
}
