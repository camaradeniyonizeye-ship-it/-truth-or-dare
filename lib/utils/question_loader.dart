import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/player.dart';

class QuestionLoader {
  /// Loads questions from JSON assets based on selected language and category
  static Future<List<Question>> loadQuestions(String language, {String category = 'Vanilla'}) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/locales/$language.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Question> questions = [];

      if (jsonData.containsKey(category)) {
        final categoryData = jsonData[category] as List<dynamic>;
        for (var item in categoryData) {
          questions.add(Question.fromJson(item));
        }
      } else {
        // Fallback: load all available categories if specific category is not found
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

  /// Processes text placeholders ({player}, {target}, {partner}) and enforces opposite-gender matching
  static String processQuestionText(
      String rawText, Player? currentPlayer, List<Player> allPlayers) {
    if (currentPlayer == null) return rawText;

    String processed = rawText.replaceAll('{player}', currentPlayer.name);

    if (processed.contains('{target}') || processed.contains('{partner}')) {
      // Enforce opposite gender matching (Male -> Female or Female -> Male)
      final oppositeGender = currentPlayer.gender == 'Male' ? 'Female' : 'Male';
      final potentialTargets = allPlayers
          .where((p) => p.id != currentPlayer.id && p.gender == oppositeGender)
          .toList();

      // Fallback to any other player if no opposite gender exists in the pool
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
