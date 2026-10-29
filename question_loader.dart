import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../models/difficulty_level.dart';
import '../models/player.dart';

class QuestionLoader {
  static Future<List<Question>> loadQuestions(String language) async {
    try {
      final assetPath = 'assets/data/locales/${language.toLowerCase()}.json';
      final data = await rootBundle.loadString(assetPath);
      return _parseQuestions(json.decode(data) as Map<String, dynamic>);
    } catch (e) {
      try {
        final data = await rootBundle.loadString('assets/data/locales/english.json');
        return _parseQuestions(json.decode(data) as Map<String, dynamic>);
      } catch (_) {
        return _getDefaultQuestions();
      }
    }
  }

  static List<Question> _parseQuestions(Map<String, dynamic> jsonData) {
    final List<Question> questions = [];
    int idCounter = 0;
    jsonData.forEach((difficultyStr, difficultyData) {
      final difficulty = DifficultyLevelExtension.fromString(difficultyStr);
      if (difficultyData is Map) {
        final truths = difficultyData['truth'] as List? ?? difficultyData['Truths'] as List? ?? [];
        final dares = difficultyData['dare'] as List? ?? difficultyData['Dares'] as List? ?? [];

        for (final q in truths) {
          if (q is String && q.trim().isNotEmpty) {
            questions.add(Question(
              id: 't_${difficultyStr}_${idCounter++}',
              type: 'truth',
              text: q.trim(),
              difficulty: difficulty,
            ));
          }
        }
        for (final q in dares) {
          if (q is String && q.trim().isNotEmpty) {
            questions.add(Question(
              id: 'd_${difficultyStr}_${idCounter++}',
              type: 'dare',
              text: q.trim(),
              difficulty: difficulty,
            ));
          }
        }
      }
    });
    return questions;
  }

  static List<Question> _getDefaultQuestions() => [
        Question(
            id: 't1',
            type: 'truth',
            text: 'What is your most embarrassing memory?',
            difficulty: DifficultyLevel.playful),
        Question(
            id: 'd1',
            type: 'dare',
            text: 'Do a silly dance for 30 seconds.',
            difficulty: DifficultyLevel.playful),
      ];

  static String processQuestionText(
      String text, Player? player, List<Player>? otherPlayers) {
    if (text.isEmpty) return text;
    String result = text;
    if (player != null) result = result.replaceAll('{name}', player.name);
    if (otherPlayers != null && otherPlayers.isNotEmpty && player != null) {
      final others =
          otherPlayers.where((p) => p.id != player.id).map((p) => p.name).toList();
      if (others.isNotEmpty) {
        final choice = others[DateTime.now().millisecondsSinceEpoch % others.length];
        result = result.replaceAll('{partner}', choice);
        result = result.replaceAll('{other_player}', choice);
      }
    }
    return result.replaceAll(RegExp(r'\{[^}]+\}'), 'someone');
  }
}
