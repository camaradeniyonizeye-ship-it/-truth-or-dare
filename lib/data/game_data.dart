import 'dart:convert';
import 'package:flutter/services.dart';

class GameData {
  static Map<String, dynamic> _loadedDatabases = {};

  static Future<void> init() async {
    try {
      final enString = await rootBundle.loadString('assets/data/locales/english.json');
      final frString = await rootBundle.loadString('assets/data/locales/french.json');
      final rwString = await rootBundle.loadString('assets/data/locales/kinyarwanda.json');
      final esString = await rootBundle.loadString('assets/data/locales/spanish.json');

      _loadedDatabases['en'] = jsonDecode(enString);
      _loadedDatabases['fr'] = jsonDecode(frString);
      _loadedDatabases['rw'] = jsonDecode(rwString);
      _loadedDatabases['es'] = jsonDecode(esString);

      print("Success: All JSON databases preloaded successfully!");
    } catch (e) {
      print("CRITICAL ERROR loading JSON databases: $e");
    }
  }

  static List<String> getQuestions(
    String lang,
    String category,
    String type, {
    required String playerName,
    required String partnerName,
    required String otherPlayer,
  }) {
    final langData = _loadedDatabases[lang];
    if (langData == null) {
      print("Warning: Language '$lang' not found in cache.");
      return [];
    }

    // Case-insensitive category lookup
    String? matchedCategoryKey;
    for (var key in langData.keys) {
      if (key.toLowerCase() == category.toLowerCase()) {
        matchedCategoryKey = key;
        break;
      }
    }

    if (matchedCategoryKey == null) {
      print("Warning: Category '$category' not found in language '$lang'.");
      return [];
    }

    final categoryData = langData[matchedCategoryKey];
    if (categoryData is! Map) return [];

    // Case-insensitive type lookup (truth / dare)
    String? matchedTypeKey;
    for (var key in categoryData.keys) {
      if (key.toLowerCase() == type.toLowerCase()) {
        matchedTypeKey = key;
        break;
      }
    }

    if (matchedTypeKey == null) {
      print("Warning: Type '$type' not found for category '$category'.");
      return [];
    }

    final List rawList = categoryData[matchedTypeKey] ?? [];

    return rawList.map((q) {
      return q.toString()
          .replaceAll('{name}', playerName)
          .replaceAll('{partner}', partnerName)
          .replaceAll('{other_player}', otherPlayer);
    }).toList();
  }
}
