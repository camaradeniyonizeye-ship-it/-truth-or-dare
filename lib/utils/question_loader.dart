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

      return questions;
    } catch (e) {
      print("Error loading questions for $language: $e");
      return [];
    }
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
