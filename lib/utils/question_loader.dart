import '../data/game_data.dart';

class QuestionLoader {
  static List<String> loadQuestions({
    required String langKey,
    required String category,
    required String type,
    String playerName = 'Player',
    String partnerName = 'Partner',
    String otherPlayer = 'Someone',
  }) {
    // Normalize language key to match GameData keys ('en', 'fr', 'rw', 'es')
    String normalizedLang = 'en';
    String lowerKey = langKey.toLowerCase();
    
    if (lowerKey.contains('fr')) {
      normalizedLang = 'fr';
    } else if (lowerKey.contains('rw') || lowerKey.contains('kinyarwanda')) {
      normalizedLang = 'rw';
    } else if (lowerKey.contains('es') || lowerKey.contains('spanish')) {
      normalizedLang = 'es';
    } else if (lowerKey.contains('en') || lowerKey.contains('english')) {
      normalizedLang = 'en';
    }

    // Fetch questions using GameData helper method with placeholder replacement
    return GameData.getQuestions(
      normalizedLang,
      category.toLowerCase(),
      type.toLowerCase(),
      playerName: playerName,
      partnerName: partnerName,
      otherPlayer: otherPlayer,
    );
  }
}
