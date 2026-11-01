import '../models/question.dart';
import '../models/player.dart';
import '../data/game_data.dart';

class QuestionLoader {
  static Future<List<Question>> loadQuestions(String language, {String category = 'Vanilla'}) async {
    try {
      final String langKey = language.toLowerCase();
      final langMap = GameData.localizedQuestions[langKey] ?? GameData.localizedQuestions['english']!;

      // Find matching category or fallback
      List> rawList = [];
      
      langMap.forEach((catKey, questions) {
        if (catKey.trim().toLowerCase() == category.trim().toLowerCase()) {
          rawList = questions;
        }
      });

      if (rawList.isEmpty) {
        // Fallback to first available category if exact match fails
        rawList = langMap.values.first;
      }

      List<Question> questions = [];
      for (var item in rawList) {
        var qMap = Map<String, dynamic>.from(item);
        if (!qMap.containsKey('category')) {
          qMap['category'] = category;
        }
        questions.add(Question.fromJson(qMap));
      }

      if (questions.isNotEmpty) return questions;
    } catch (e) {
      print("Embedded data load error for $language: $e");
    }

    return _getFallbackQuestions(category);
  }

  static List<Question> _getFallbackQuestions(String category) {
    return [
      Question(id: '1', type: 'truth', text: 'What is your wildest secret fantasy with {target}?', category: category),
      Question(id: '2', type: 'dare', text: 'Give {target} a 10-second sensual massage on the shoulders.', category: category),
      Question(id: '3', type: 'truth', text: 'Who in this room do you find most secretly attractive?', category: category),
      Question(id: '4', type: 'dare', text: 'Whisper something very seductive into {partner}\'s ear.', category: category),
    ];
  }

  static String processQuestionText(
      String rawText, Player? currentPlayer, List<Player> allPlayers) {
    if (currentPlayer == null) return rawText;

    String processed = rawText.replaceAll('{player}', currentPlayer.name);

    if (processed.contains('{target}') || processed.contains('{partner}')) {
      final otherPlayers = allPlayers.where((p) => p.id != currentPlayer.id).toList();

      if (otherPlayers.isNotEmpty) {
        final currentPlayerGender = currentPlayer.gender.trim().toLowerCase();
        
        // Strict opposite-gender filtering
        final oppositeGenderTargets = otherPlayers.where((p) {
          final pGender = p.gender.trim().toLowerCase();
          return pGender != currentPlayerGender && (pGender == 'male' || pGender == 'female');
        }).toList();

        final targetPool = oppositeGenderTargets.isNotEmpty ? oppositeGenderTargets : otherPlayers;
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
