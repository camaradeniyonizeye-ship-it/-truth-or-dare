import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/player.dart';

class QuestionLoader {
  static Future<List<Question>> loadQuestions(String language, {String category = 'Vanilla'}) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/locales/$language.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Question> questions = [];
      String targetCategory = category.trim().toLowerCase();
      String? matchedKey;

      jsonData.forEach((key, value) {
        if (key.trim().toLowerCase() == targetCategory) {
          matchedKey = key;
        }
      });

      if (matchedKey != null && jsonData[matchedKey] is List) {
        final categoryData = jsonData[matchedKey] as List<dynamic>;
        for (var item in categoryData) {
          questions.add(Question.fromJson(item));
        }
      } else {
        jsonData.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              questions.add(Question.fromJson(item));
            }
          }
        });
      }

      if (questions.isNotEmpty) return questions;
    } catch (e) {
      print("JSON asset load error for $language: $e");
    }

    // Fallback default questions so the game never runs empty
    return _getFallbackQuestions(category);
  }

  static List<Question> _getFallbackQuestions(String category) {
    return [
      Question(id: '1', type: 'truth', text: 'What is your wildest secret fantasy with {target}?', category: category),
      Question(id: '2', type: 'dare', text: 'Give {target} a 10-second sensual massage on the shoulders.', category: category),
      Question(id: '3', type: 'truth', text: 'Who in this room do you find most secretly attractive?', category: category),
      Question(id: '4', type: 'dare', text: 'Whisper something very seductive into {partner}\'s ear.', category: category),
      Question(id: '5', type: 'truth', text: 'What is the most embarrassing thing that happened to you on a date?', category: category),
      Question(id: '6', type: 'dare', text: 'Post a funny selfie making a kissing face to your status.', category: category),
    ];
  }

  static String processQuestionText(
      String rawText, Player? currentPlayer, List<Player> allPlayers) {
    if (currentPlayer == null) return rawText;

    String processed = rawText.replaceAll('{player}', currentPlayer.name);

    if (processed.contains('{target}') || processed.contains('{partner}')) {
      final oppositeGender = currentPlayer.gender == 'Male' ? 'Female' : 'Male';
      final potentialTargets = allPlayers
          .where((p) => p.id != currentPlayer.id && p.gender == oppositeGender)
          .toList();

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
