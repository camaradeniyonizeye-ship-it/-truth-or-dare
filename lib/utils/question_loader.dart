import '../data/game_data.dart';

class Player {
  final String name;
  final String gender; // 'male' or 'female'
  Player? partner;     // Strictly opposite-sex partner
  String? lastChoice;  // Tracks 'truth' or 'dare' from their previous turn

  Player({
    required this.name,
    required this.gender,
    this.partner,
    this.lastChoice,
  });

  /// Automatically pairs players strictly by opposite sex across all categories
  static void assignOppositeSexPartners(List<Player> players) {
    List<Player> males = players.where((p) => p.gender.toLowerCase() == 'male').toList();
    List<Player> females = players.where((p) => p.gender.toLowerCase() == 'female').toList();

    males.shuffle();
    females.shuffle();

    // Clear existing pairings
    for (var p in players) {
      p.partner = null;
    }

    int count = males.length < females.length ? males.length : females.length;
    for (int i = 0; i < count; i++) {
      males[i].partner = females[i];
      females[i].partner = males[i];
    }
  }
}

class QuestionLoader {
  static List<String> loadQuestions({
    required String langKey,
    required String category,
    required String type,
    required Player currentPlayer,
    String otherPlayer = 'Someone',
  }) {
    // 1. Normalize language key
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

    String chosenType = type.toLowerCase();

    // 2. Rule Enforcement: No choosing Truth twice continuously
    if (chosenType == 'truth' && currentPlayer.lastChoice?.toLowerCase() == 'truth') {
      throw Exception("${currentPlayer.name} cannot choose Truth twice in a row! Please pick Dare.");
    }

    // 3. Retrieve strict opposite-sex partner name
    String partnerName = currentPlayer.partner?.name ?? 'Partner';

    // 4. Record this turn's valid choice
    currentPlayer.lastChoice = chosenType;

    // 5. Fetch questions from GameData with placeholders injected
    return GameData.getQuestions(
      normalizedLang,
      category.toLowerCase(),
      chosenType,
      playerName: currentPlayer.name,
      partnerName: partnerName,
      otherPlayer: otherPlayer,
    );
  }
}
