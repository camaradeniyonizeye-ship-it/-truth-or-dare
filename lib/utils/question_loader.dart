import 'dart:math';

import '../models/player.dart';
import '../models/question.dart';
import '../data/game_data.dart';

class QuestionLoader {
  static final Map<Player, String> _lastChoices = {};
  static final Map<Player, Player> _partners = {};
  static final Random _random = Random();
  
  // Session tracking to ensure questions never repeat until the app is closed
  static final Set<String> _usedQuestionTexts = {};

  static void assignPartner(Player player, Player partner) {
    _partners[player] = partner;
  }

  static Future<List<Question>> loadQuestions(
    String langKey, {
    String category = 'vanilla',
    String type = 'truth',
    Player? currentPlayer,
    String otherPlayer = 'Someone',
  }) async {
    final normalizedLang = _normalizeLanguage(langKey);
    final chosenType = type.toLowerCase();
    final chosenCategory = category.toLowerCase();

    if (currentPlayer != null) {
      final previousChoice = _lastChoices[currentPlayer];
      if (chosenType == 'truth' && previousChoice == 'truth') {
        throw Exception(
          "${currentPlayer.name} cannot choose Truth twice in a row! Please pick Dare.",
        );
      }
      _lastChoices[currentPlayer] = chosenType;
    }

    final rawStrings = GameData.getQuestions(
      normalizedLang,
      chosenCategory,
      chosenType,
    );

    // Filter out questions already served in this session
    var availableStrings = rawStrings.where((q) => !_usedQuestionTexts.contains(q)).toList();

    // If all questions have been exhausted in this session, reset tracker to loop fresh
    if (availableStrings.isEmpty) {
      _usedQuestionTexts.clear();
      availableStrings = List.from(rawStrings);
    }

    // Mark selected questions as used for the rest of the app session
    for (var q in availableStrings) {
      _usedQuestionTexts.add(q);
    }

    return List<Question>.generate(availableStrings.length, (index) {
      return Question(
        id: 'q_${index + 1}',
        text: availableStrings[index],
        type: chosenType,
        category: chosenCategory,
      );
    });
  }

  static String _normalizeLanguage(String langKey) {
    final lowerKey = langKey.toLowerCase();
    if (lowerKey.contains('fr')) return 'fr';
    if (lowerKey.contains('rw') || lowerKey.contains('kinyarwanda')) return 'rw';
    if (lowerKey.contains('es') || lowerKey.contains('spanish')) return 'es';
    return 'en';
  }

  static List<Player> _otherPlayers(Player? currentPlayer, List<Player> players) {
    return players.where((player) => player.id != currentPlayer?.id).toList();
  }

  static Player? _chooseRandom(List<Player> candidates) {
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  static Player? _chooseTarget(Player? currentPlayer, List<Player> players) {
    final others = _otherPlayers(currentPlayer, players);
    if (others.isEmpty) return null;

    final assigned = currentPlayer == null ? null : _partners[currentPlayer];
    final validAssigned = assigned != null &&
        others.any((player) => player.id == assigned.id);

    if (currentPlayer != null) {
      final gender = currentPlayer.gender.toLowerCase();
      final oppositeGender = gender == 'male'
          ? 'female'
          : gender == 'female'
              ? 'male'
              : null;

      if (oppositeGender != null) {
        final oppositePlayers = others
            .where((player) => player.gender.toLowerCase() == oppositeGender)
            .toList();
        if (oppositePlayers.isNotEmpty) {
          if (validAssigned && assigned!.gender.toLowerCase() == oppositeGender) {
            return assigned;
          }
          return _chooseRandom(oppositePlayers);
        }
      }
    }

    if (validAssigned) return assigned;
    return _chooseRandom(others);
  }

  static String _chooseGenderName(
    String gender,
    Player? currentPlayer,
    List<Player> players, {
    required String fallback,
  }) {
    final candidates = _otherPlayers(currentPlayer, players)
        .where((player) => player.gender.toLowerCase() == gender)
        .toList();
    return _chooseRandom(candidates)?.name ?? fallback;
  }

  static String processQuestionText(
    String text, [
    Player? currentPlayer,
    Object? otherPlayerOrPlayers,
  ]) {
    final players = otherPlayerOrPlayers is List<Player>
        ? otherPlayerOrPlayers
        : <Player>[];
    
    final playerName = currentPlayer?.name ?? 'Player';
    final targetPlayer = _chooseTarget(currentPlayer, players);
    final partnerName = targetPlayer?.name ?? 'Someone';
    final otherPlayer = targetPlayer?.name ?? 'Someone';

    final maleName = _chooseGenderName('male', currentPlayer, players, fallback: otherPlayer);
    final femaleName = _chooseGenderName('female', currentPlayer, players, fallback: otherPlayer);

    return text
        .replaceAll('{name}', playerName)
        .replaceAll('{partner}', partnerName)
        .replaceAll('{target}', otherPlayer)
        .replaceAll('{other_player}', otherPlayer)
        .replaceAll('{male_player}', maleName)
        .replaceAll('{female_player}', femaleName);
  }
}
