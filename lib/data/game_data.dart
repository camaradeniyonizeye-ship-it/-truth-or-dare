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

      print("SUCCESS: JSON databases loaded. Keys found in EN: ${_loadedDatabases['en']?.keys.toList()}");
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
      print("DEBUG: Language '$lang' not found in cache. Using fallbacks.");
      return _getFallbackQuestions(type, playerName, partnerName, otherPlayer);
    }

    // Flexible category search
    String? matchedCategoryKey;
    for (var key in langData.keys) {
      if (key.toLowerCase().contains(category.toLowerCase()) || 
          category.toLowerCase().contains(key.toLowerCase())) {
        matchedCategoryKey = key;
        break;
      }
    }

    if (matchedCategoryKey == null) {
      print("DEBUG: Category '$category' not found in lang '$lang'. Available: ${langData.keys}");
      return _getFallbackQuestions(type, playerName, partnerName, otherPlayer);
    }

    final categoryData = langData[matchedCategoryKey];
    if (categoryData is! Map) {
      return _getFallbackQuestions(type, playerName, partnerName, otherPlayer);
    }

    // Flexible type search (truth/dare)
    String? matchedTypeKey;
    for (var key in categoryData.keys) {
      if (key.toLowerCase().contains(type.toLowerCase()) || 
          type.toLowerCase().contains(key.toLowerCase())) {
        matchedTypeKey = key;
        break;
      }
    }

    if (matchedTypeKey == null) {
      print("DEBUG: Type '$type' not found under category '$matchedCategoryKey'. Available: ${categoryData.keys}");
      return _getFallbackQuestions(type, playerName, partnerName, otherPlayer);
    }

    final List rawList = categoryData[matchedTypeKey] ?? [];
    if (rawList.isEmpty) {
      return _getFallbackQuestions(type, playerName, partnerName, otherPlayer);
    }

    return rawList.map((q) {
      return q.toString()
          .replaceAll('{name}', playerName)
          .replaceAll('{partner}', partnerName)
          .replaceAll('{other_player}', otherPlayer);
    }).toList();
  }

  // Emergency fallback list so the game never shows "No questions available"
  static List<String> _getFallbackQuestions(String type, String playerName, String partnerName, String otherPlayer) {
    if (type.toLowerCase().contains('truth')) {
      return [
        "$playerName, what is your biggest secret?",
        "$playerName, what do you secretly love most about $partnerName?",
        "$playerName, what was your most embarrassing moment with $otherPlayer?"
      ];
    } else {
      return [
        "$playerName, give $partnerName a romantic massage for 1 minute.",
        "$playerName, whisper a secret in $otherPlayer's ear.",
        "$playerName, imitate your favorite celebrity right now."
      ];
    }
  }
}
