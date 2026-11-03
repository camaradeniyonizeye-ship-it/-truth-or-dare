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

  /// Returns unmodified templates so runtime question processing can replace
  /// every token using the selected player and current roster.
  static List<String> getQuestions(
    String lang,
    String category,
    String type,
  ) {
    final langData = _loadedDatabases[lang];
    if (langData == null) {
      print("DEBUG: Language '$lang' not found in cache. Using fallbacks.");
      return _getFallbackQuestions(type);
    }

    String? matchedCategoryKey;
    for (final dynamic rawKey in langData.keys) {
      final key = rawKey.toString();
      if (key.toLowerCase().contains(category.toLowerCase()) ||
          category.toLowerCase().contains(key.toLowerCase())) {
        matchedCategoryKey = key;
        break;
      }
    }

    if (matchedCategoryKey == null) {
      print("DEBUG: Category '$category' not found in lang '$lang'. Available: ${langData.keys}");
      return _getFallbackQuestions(type);
    }

    final categoryData = langData[matchedCategoryKey];
    if (categoryData is! Map) return _getFallbackQuestions(type);

    String? matchedTypeKey;
    for (final dynamic rawKey in categoryData.keys) {
      final key = rawKey.toString();
      if (key.toLowerCase().contains(type.toLowerCase()) ||
          type.toLowerCase().contains(key.toLowerCase())) {
        matchedTypeKey = key;
        break;
      }
    }

    if (matchedTypeKey == null) {
      print("DEBUG: Type '$type' not found under category '$matchedCategoryKey'. Available: ${categoryData.keys}");
      return _getFallbackQuestions(type);
    }

    final rawList = categoryData[matchedTypeKey];
    if (rawList is! List || rawList.isEmpty) return _getFallbackQuestions(type);
    return rawList.map((question) => question.toString()).toList();
  }

  /// Emergency templates still use the same runtime placeholder pipeline.
  static List<String> _getFallbackQuestions(String type) {
    if (type.toLowerCase().contains('truth')) {
      return [
        'Dear {name}, what is your biggest secret?',
        'Dear {name}, what do you secretly love most about {partner}?',
        'Dear {name}, what was your most embarrassing moment with {other_player}?',
      ];
    }

    return [
      'Dear {name}, give {partner} a friendly compliment.',
      'Dear {name}, share a fun secret with {other_player}.',
      'Dear {name}, imitate your favorite celebrity right now.',
    ];
  }
}
