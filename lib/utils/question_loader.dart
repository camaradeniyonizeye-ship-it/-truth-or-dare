import 'dart:math';

import '../models/player.dart';
import '../models/question.dart';
import '../data/game_data.dart';

class QuestionLoader {
  static final Map<Player, String> _lastChoices = {};
  static final Map<Player, Player> _partners = {};
  static final Random _random = Random();

  /// Registers a preferred partner. Runtime matching still validates that the
  /// partner is another player and prefers an opposite-gender match.
  static void assignPartner(Player player, Player partner) {
    _partners[player] = partner;
  }

  /// Loads raw question templates. Names are substituted at the moment a
  /// question is shown, when the active player and full roster are available.
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

    // Preserve the existing rule for callers that load questions for a player.
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

    return List<Question>.generate(rawStrings.length, (index) {
      return Question(
        id: 'q_${index + 1}',
        text: rawStrings[index],
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

  /// Replaces all supported question tokens using players from the current
  /// round. `{partner}` and `{target}` share the opposite-gender-preferred
  /// target; if no opposite-gender player is available, any other player is
  /// eligible. Gender-specific tokens fall back to that target when needed.
  static String processQuestionText(
    String text, [
    Player? currentPlayer,
    Object? otherPlayerOrPlayers,
  ]) {
    final players = otherPlayerOrPlayers is List<Player>
        ? otherPlayerOrPlayers
        : <Player>[];
    final playerName = currentPlayer?.name ?? 'Player';
    final others = _otherPlayers(currentPlayer, players);
    final explicitOtherPlayer = otherPlayerOrPlayers is String
        ? otherPlayerOrPlayers
        : null;
    final otherPlayerName = explicitOtherPlayer ?? _chooseRandom(others)?.name ?? 'someone';
    final target = _chooseTarget(currentPlayer, players);
    final targetName = target?.name ?? explicitOtherPlayer ?? 'someone';
    final partnerName = targetName;
    final maleName = _chooseGenderName(
      'male',
      currentPlayer,
      players,
      fallback: targetName,
    );
    final femaleName = _chooseGenderName(
      'female',
      currentPlayer,
      players,
      fallback: targetName,
    );

    return text
        .replaceAll('{name}', playerName)
        .replaceAll('{player}', playerName)
        .replaceAll('{partner}', partnerName)
        .replaceAll('{target}', targetName)
        .replaceAll('{other_player}', otherPlayerName)
        .replaceAll('{other_male}', maleName)
        .replaceAll('{other_female}', femaleName);
  }
}
