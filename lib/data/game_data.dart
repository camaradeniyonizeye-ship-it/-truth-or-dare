import 'dart:convert';
import 'package:flutter/services.dart';

class GameData {
  static Map<String, dynamic> _loadedDatabases = {};

  static Future<init> init() async { // or Future<void> init() async
    try {
      // Correct paths pointing directly to assets/data/locales/
      final enString = await rootBundle.loadString('assets/data/locales/english.json');
      final frString = await rootBundle.loadString('assets/data/locales/french.json');
      final rwString = await rootBundle.loadString('assets/data/locales/kinyarwanda.json');
      final esString = await rootBundle.loadString('assets/data/locales/spanish.json');

      _loadedDatabases['en'] = jsonDecode(enString);
      _loadedDatabases['fr'] = jsonDecode(frString);
      _loadedDatabases['rw'] = jsonDecode(rwString);
      _loadedDatabases['es'] = jsonDecode(esString);

      print("Success: All JSON databases preloaded from locales!");
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
      print("Warning: Language '$lang' not found in cache. Using fallback defaults.");
      return [];
    }

    try {
      final categoryData = langData[category];
      if (categoryData == null) {
        print("Warning: Category '$category' not found for language '$lang'.");
        return [];
      }

      final List rawList = categoryData[type] ?? [];

      return rawList.map((q) {
        return q.toString()
            .replaceAll('{name}', playerName)
            .replaceAll('{partner}', partnerName)
            .replaceAll('{other_player}', otherPlayer);
      }).toList();
      
    } catch (e) {
      print("Error parsing question structure: $e");
      return [];
    }
  }
}
