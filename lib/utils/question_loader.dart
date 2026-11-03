import '../models/player.dart';
import '../models/question.dart';
import '../data/game_data.dart';

class QuestionLoader {
  static final Map<Player, String> _lastChoices = {};
  static final Map<Player, Player> _partners = {};

  static void assignPartner(Player player, Player partner) {
    _partners[player] = partner;
  }

  static Player? _findPartner(Player currentPlayer, List<Player> allPlayers) {
    final oppositeGender = currentPlayer.gender.toLowerCase() == 'male'
        ? 'female'
        : 'male';

    final sameGender = allPlayers
        .where((p) => p.id != currentPlayer.id)
        .toList();

    final oppositeGenderPlayers = sameGender
        .where((p) => p.gender.toLowerCase() == oppositeGender)
        .toList();

    if (oppositeGenderPlayers.isNotEmpty) {
      oppositeGenderPlayers.shuffle();
      return oppositeGenderPlayers.first;
    }

    if (sameGender.isNotEmpty) {
      sameGender.shuffle();
      return sameGender.first;
    }

    return null;
  }

  static String _pickNameForGender(
    String gender,
    Player? currentPlayer,
    List<Player> players, {
    required String fallback,
  }) {
    if (players.isEmpty) return fallback;

    final withoutCurrent = players
        .where((p) => currentPlayer == null || p.id != currentPlayer.id)
        .toList();

    if (withoutCurrent.isEmpty) return fallback;

    final candidates = withoutCurrent
        .where((p) => p.gender.toLowerCase() == gender.toLowerCase())
        .toList();

    if (candidates.isNotEmpty) {
      candidates.shuffle();
      return candidates.first.name;
    }

    return withoutCurrent.first.name;
  }

  /// Loads questions and returns List<Question> safely for difficulty selection.
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
    String chosenCategory = category.toLowerCase();

    // 2. Rule Enforcement: No choosing Truth twice continuously
    if (currentPlayer != null) {
      String? previousChoice = _lastChoices[currentPlayer];
      if (chosenType == 'truth' && previousChoice?.toLowerCase() == 'truth') {
        throw Exception("${currentPlayer.name} cannot choose Truth twice in a row! Please pick Dare.");
      }
      _lastChoices[currentPlayer] = chosenType;
    }

    String playerName = currentPlayer?.name ?? 'Player';
    Player? partnerObj = currentPlayer != null ? (_partners[currentPlayer] ?? null) : null;
    String partnerName = partnerObj?.name ?? 'Partner';
    String targetName = partnerName == 'Partner' ? otherPlayer : partnerName;

    String otherMale = (currentPlayer != null && currentPlayer.gender.toLowerCase() == 'male')
        ? targetName
        : otherPlayer;
    String otherFemale = (currentPlayer != null && currentPlayer.gender.toLowerCase() == 'female')
        ? targetName
        : otherPlayer;

    // 3. Fetch raw strings from GameData cache
    List<String> rawStrings = GameData.getQuestions(
      normalizedLang,
      chosenCategory,
      chosenType,
      playerName: playerName,
      partnerName: partnerName,
      otherPlayer: otherPlayer,
      otherMale: otherMale,
      otherFemale: otherFemale,
      target: targetName,
    );

    // 4. Map strings to Question objects supplying id, text, type, and category
    int counter = 0;
    return rawStrings.map<Question>((qText) {
      String processed = qText
          .replaceAll('{name}', playerName)
          .replaceAll('{partner}', partnerName)
          .replaceAll('{other_player}', otherPlayer)
          .replaceAll('{other_male}', otherMale)
          .replaceAll('{other_female}', otherFemale)
          .replaceAll('{target}', targetName);

      counter++;
      return Question(
        id: 'q_$counter',
        text: processed,
        type: chosenType,
        category: chosenCategory,
      );
    }).toList();
  }

  /// Processes text placeholders supporting flexible arguments matching game_screen.dart calls.
  static String processQuestionText(
    String text, [
    Player? currentPlayer,
    Object? otherPlayerOrPlayers,
  ]) {
    String playerName = currentPlayer?.name ?? 'Player';
    Player? partnerObj = currentPlayer != null ? _partners[currentPlayer] : null;
    String partnerName = partnerObj?.name ?? 'Partner';
    String otherPlayer = 'Someone';
    List<Player> allPlayers = [];

    if (otherPlayerOrPlayers is String) {
      otherPlayer = otherPlayerOrPlayers;
    } else if (otherPlayerOrPlayers is List<Player>) {
      allPlayers = otherPlayerOrPlayers;
      final others = allPlayers.where((p) => p != currentPlayer).toList();
      if (others.isNotEmpty) {
        others.shuffle();
        otherPlayer = others.first.name;
      }
    }

    if (currentPlayer != null && partnerObj == null && allPlayers.isNotEmpty) {
      partnerObj = _findPartner(currentPlayer, allPlayers);
      partnerName = partnerObj?.name ?? partnerName;
    }

    final targetName = partnerName == 'Partner' ? otherPlayer : partnerName;
    final otherMale = _pickNameForGender(
      'male',
      currentPlayer,
      allPlayers,
      fallback: targetName,
    );
    final otherFemale = _pickNameForGender(
      'female',
      currentPlayer,
      allPlayers,
      fallback: targetName,
    );

    return text
        .replaceAll('{name}', playerName)
        .replaceAll('{partner}', partnerName)
        .replaceAll('{other_player}', otherPlayer)
        .replaceAll('{other_male}', otherMale)
        .replaceAll('{other_female}', otherFemale)
        .replaceAll('{target}', targetName);
  }
}
