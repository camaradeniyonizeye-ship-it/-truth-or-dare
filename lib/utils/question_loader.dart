import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/player.dart';

class QuestionLoader {
  static Future<List<Question>> loadQuestions(String language, {String category = 'Vanilla'}) async {
    try {
      final String filename = language.toLowerCase();
      final String jsonString = await rootBundle.loadString('assets/data/locales/$filename.json');
      final dynamic decoded = json.decode(jsonString);

      List<Question> questions = [];

      if (decoded is Map<String, dynamic>) {
        String targetCategory = category.trim().toLowerCase();
        String? matchedKey;

        decoded.forEach((key, value) {
          if (key.trim().toLowerCase() == targetCategory) {
            matchedKey = key;
          }
        });

        if (matchedKey != null && decoded[matchedKey] is List) {
          final categoryData = decoded[matchedKey] as List<dynamic>;
          for (var item in categoryData) {
            questions.add(Question.fromJson(item));
          }
        } else {
          decoded.forEach((key, value) {
            if (value is List) {
              for (var item in value) {
                questions.add(Question.fromJson(item));
              }
            }
          });
        }
      } else if (decoded is List) {
        for (var item in decoded) {
          questions.add(Question.fromJson(item));
        }
      }

      if (questions.isNotEmpty) return questions;
    } catch (e) {
      print("JSON asset load error for $language: $e");
    }

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

    // 1. Replace player placeholder with the active turn player's name
    String processed = rawText.replaceAll('{player}', currentPlayer.name);

    // 2. Strict Partnering / Target Substitution Logic
    if (processed.contains('{target}') || processed.contains('{partner}')) {
      // Find all other players excluding the current player
      final otherPlayers = allPlayers.where((p) => p.id != currentPlayer.id).toList();

      if (otherPlayers.isNotEmpty) {
        // Strictly prioritize opposite gender
        final currentPlayerGender = currentPlayer.gender.trim().toLowerCase();
        final oppositeGenderTargets = otherPlayers.where((p) {
          final pGender = p.gender.trim().toLowerCase();
          return pGender != currentPlayerGender && (pGender == 'male' || pGender == 'female');
        }).toList();

        // Fallback pool if no opposite gender exists (e.g. same-gender group)
        final targetPool = oppositeGenderTargets.isNotEmpty ? oppositeGenderTargets : otherPlayers;

        // Select a strict, distinct target
        final target = targetPool[DateTime.now().millisecondsSinceEpoch % targetPool.length];

        processed = processed
            .replaceAll('{target}', target.name)
            .replaceAll('{partner}', target.name);
      } else {
        // Absolute fallback if playing solo or list is empty
        processed = processed
            .replaceAll('{target}', 'someone')
            .replaceAll('{partner}', 'someone');
      }
    }

    return processed;
  }
}
