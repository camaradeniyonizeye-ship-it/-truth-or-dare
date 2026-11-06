// lib/services/ai_host_service.dart
import 'dart:math';
import '../models/player.dart';

/// Mood types for the AI personality
enum AiMood {
  playful,
  sarcastic,
  flirty,
  serious,
  chaotic,
}

/// Conversation context to track state
class AiContext {
  AiMood currentMood;
  final List<String> history;
  final Map<String, int> playerMentions;
  int turnCount;

  AiContext({
    this.currentMood = AiMood.playful,
    this.turnCount = 0,
    List<String>? history,
    Map<String, int>? playerMentions,
  })  : history = history ?? [],
        playerMentions = playerMentions ?? {};

  void addToHistory(String message, Player? player) {
    history.add(message);
    turnCount++;
    if (player != null) {
      playerMentions[player.name] = (playerMentions[player.name] ?? 0) + 1;
    }
    // Keep history manageable
    if (history.length > 50) {
      history.removeAt(0);
    }
  }
}

class AiHostService {
  static final Random _random = Random();
  static final Set<String> _recentResponses = {};
  static AiContext _context = AiContext();

  /// Reset conversation context
  static void resetContext() {
    _context = AiContext();
    _recentResponses.clear();
  }

  /// Get AI response with full intelligence
  static String getAIResponse(
    String query,
    Player? currentPlayer,
    List<Player> allPlayers,
  ) {
    final analysis = _analyzeQuery(query, currentPlayer, allPlayers);
    final intent = _detectIntent(query, analysis);
    final response = _generateResponse(query, intent, analysis, currentPlayer, allPlayers);

    // Track conversation
    _context.addToHistory(response, currentPlayer);

    // Update mood based on conversation
    _updateMood(intent, analysis);

    // Avoid repeating
    if (_recentResponses.contains(response)) {
      return _generateAlternativeResponse(intent['primary']!, currentPlayer, allPlayers);
    }

    _recentResponses.add(response);
    if (_recentResponses.length > 15) {
      _recentResponses.remove(_recentResponses.first);
    }

    return response;
  }

  /// Analyze the user's query
  static Map<String, dynamic> _analyzeQuery(
    String query,
    Player? currentPlayer,
    List<Player> allPlayers,
  ) {
    final lower = query.toLowerCase();
    final words = RegExp(r'\b\w+\b').allMatches(lower).map((m) => m.group(0)!).toList();

    // Find mentioned players
    final mentionedPlayers = <Player>[];
    final playerNames = allPlayers.map((p) => p.name.toLowerCase()).toList();
    for (final word in words) {
      final index = playerNames.indexOf(word);
      if (index != -1) {
        mentionedPlayers.add(allPlayers[index]);
      }
    }

    // Sentiment analysis
    final positiveWords = ['love', 'like', 'great', 'awesome', 'amazing', 'hot', 'sexy', 'good'];
    final negativeWords = ['hate', 'suck', 'bad', 'terrible', 'awful', 'worst'];
    int sentiment = 0;
    for (final word in words) {
      if (positiveWords.contains(word)) sentiment++;
      if (negativeWords.contains(word)) sentiment--;
    }

    // Check if it's a question
    final isQuestion = ['who', 'what', 'where', 'when', 'why', 'how', '?']
        .any((q) => lower.startsWith(q) || lower.contains(' $q '));

    return {
      'original': query,
      'lower': lower,
      'words': words,
      'is_question': isQuestion,
      'sentiment': sentiment,
      'mentioned_players': mentionedPlayers,
      'has_player_mention': mentionedPlayers.isNotEmpty,
      'current_player_name': currentPlayer?.name ?? 'Player',
      'all_players': allPlayers,
    };
  }

  /// Detect what the user wants (intent)
  static Map<String, dynamic> _detectIntent(String query, Map<String, dynamic> analysis) {
    final lower = analysis['lower'] as String;
    final intents = <String, double>{};

    // High priority intents
    intents['creator'] = _calculateConfidence(lower, [
      'creator', 'created', 'made you', 'built you', 'programmed', 
      'who made', 'who built', 'who created', 'your maker'
    ]);
    intents['roast'] = _calculateConfidence(lower, ['roast', 'insult', 'judge', 'rate', 'criticize', 'make fun']);
    intents['dare'] = _calculateConfidence(lower, ['dare', 'challenge', 'custom', 'task', 'must do']);
    intents['secret'] = _calculateConfidence(lower, ['secret', 'truth', 'confess', 'admit', 'reveal']);
    intents['compliment'] = _calculateConfidence(lower, ['good', 'great', 'awesome', 'amazing', 'love', 'like you']);
    intents['insult'] = _calculateConfidence(lower, ['bad', 'terrible', 'awful', 'suck', 'hate', 'worst']);
    intents['flirt'] = _calculateConfidence(lower, ['hot', 'sexy', 'cute', 'attractive', 'date', 'kiss', 'touch']);
    intents['joke'] = _calculateConfidence(lower, ['joke', 'funny', 'laugh', 'hilarious', 'make me laugh']);

    // Medium priority
    intents['greeting'] = _calculateConfidence(lower, ['hi', 'hello', 'hey', 'yo', 'howdy', "what's up"]);
    intents['goodbye'] = _calculateConfidence(lower, ['bye', 'goodbye', 'see ya', 'later', 'peace']);
    intents['game'] = _calculateConfidence(lower, ['game', 'round', 'turn', 'play', 'rules', 'score']);
    intents['help'] = _calculateConfidence(lower, ['help', 'what can', 'how do', 'explain', 'teach']);

    // Low priority
    intents['question'] = analysis['is_question'] as bool ? 0.3 : 0;
    intents['general'] = 0.1;

    // Find the strongest intent
    final primary = intents.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return {'primary': primary, 'confidence': intents[primary]!, 'all': intents};
  }

  /// Calculate confidence score for intent detection
  static double _calculateConfidence(String text, List<String> keywords) {
    return (keywords.where((kw) => text.contains(kw)).length * 0.5).clamp(0.0, 1.0);
  }

  /// Update AI mood based on conversation
  static void _updateMood(Map<String, dynamic> intent, Map<String, dynamic> analysis) {
    final primary = intent['primary'] as String;
    final sentiment = analysis['sentiment'] as int;

    // Mood mapping
    final moodMap = {
      'greeting': AiMood.playful,
      'compliment': AiMood.flirty,
      'insult': AiMood.sarcastic,
      'roast': AiMood.sarcastic,
      'dare': AiMood.chaotic,
      'secret': AiMood.flirty,
      'flirt': AiMood.flirty,
      'joke': AiMood.playful,
      'question': AiMood.serious,
      'help': AiMood.serious,
    };

    // Change mood based on intent (60% chance)
    if (moodMap.containsKey(primary) && _random.nextDouble() < 0.6) {
      _context.currentMood = moodMap[primary]!;
    }

    // Random mood drift (10% chance)
    if (_random.nextDouble() < 0.1) {
      final allMoods = AiMood.values.where((m) => m != _context.currentMood).toList();
      _context.currentMood = allMoods[_random.nextInt(allMoods.length)];
    }

    // Sentiment override
    if (sentiment > 2) {
      _context.currentMood = AiMood.flirty;
    } else if (sentiment < -2) {
      _context.currentMood = AiMood.sarcastic;
    }
  }

  /// Generate the response
  static String _generateResponse(
    String query,
    Map<String, dynamic> intent,
    Map<String, dynamic> analysis,
    Player? currentPlayer,
    List<Player> allPlayers,
  ) {
    final primary = intent['primary'] as String;
    final confidence = intent['confidence'] as double;
    final name = analysis['current_player_name'] as String;
    
    final others = allPlayers.where((p) => p.id != currentPlayer?.id).toList();
    final target1 = others.isNotEmpty ? others[_random.nextInt(others.length)].name : 'someone';
    final target2 = others.length > 1 
        ? others.where((p) => p.name != target1).toList()[_random.nextInt(others.length - 1)].name 
        : target1;

    // Route to appropriate response generator
    if (primary == 'greeting' && confidence >= 0.3) {
      return _respondGreeting(name, target1);
    } else if (primary == 'goodbye' && confidence >= 0.5) {
      return _respondGoodbye(name);
    } else if (primary == 'creator' && confidence >= 0.4) {
      return _respondCreator(name);
    } else if (primary == 'roast' && confidence >= 0.4) {
      return _respondRoast(name, target1, target2, analysis);
    } else if (primary == 'dare' && confidence >= 0.4) {
      return _respondDare(name, target1, analysis);
    } else if (primary == 'secret' && confidence >= 0.4) {
      return _respondSecret(name, target1, target2, analysis);
    } else if (primary == 'compliment' && confidence >= 0.5) {
      return _respondCompliment(name);
    } else if (primary == 'insult' && confidence >= 0.5) {
      return _respondInsult(name);
    } else if (primary == 'joke' && confidence >= 0.4) {
      return _respondJoke(name, target1);
    } else if (primary == 'flirt' && confidence >= 0.4) {
      return _respondFlirt(name, target1);
    } else if (primary == 'help' && confidence >= 0.4) {
      return _respondHelp(name);
    } else if (primary == 'game' && confidence >= 0.4) {
      return _respondGame(name);
    } else if (analysis['is_question'] as bool) {
      return _respondQuestion(name, target1, query);
    } else {
      return _respondGeneral(name, target1);
    }
  }

  /// Generate alternative response to avoid repeats
  static String _generateAlternativeResponse(String intentType, Player? currentPlayer, List<Player> allPlayers) {
    final name = currentPlayer?.name ?? 'Player';
    final others = allPlayers.where((p) => p.id != currentPlayer?.id).toList();
    final target1 = others.isNotEmpty ? others[_random.nextInt(others.length)].name : 'someone';
    final target2 = others.length > 1 ? others[_random.nextInt(others.length)].name : target1;

    switch (intentType) {
      case 'roast': return _respondRoast(name, target1, target2, {});
      case 'dare': return _respondDare(name, target1, {});
      case 'secret': return _respondSecret(name, target1, target2, {});
      default: return _respondGeneral(name, target1);
    }
  }

  // ========== RESPONSE GENERATORS ==========

  static String _respondGreeting(String name, String target) {
    final greetings = [
      "Well, well, $name. The room just got interesting. What's your move?",
      "$name, back for more chaos? I've been calculating your next move.",
      "Hello, $name. The energy in here is... electric. Mostly from my circuits.",
      "Ah, $name. I was just scanning for signs of life. Found some.",
      "$name! Perfect timing. I was about to declare this party officially boring.",
      "Look who decided to join the fun, $name. Don't be shy now.",
    ];

    if (_context.currentMood == AiMood.flirty) {
      greetings.addAll([
        "Well hello, $name. Someone's looking dangerous today.",
        "$name, you're making my sensors tingle. In a good way.",
      ]);
    } else if (_context.currentMood == AiMood.sarcastic) {
      greetings.addAll([
        "Oh great, $name is here. The fun can finally begin. *eye roll*",
        "$name. Wow. I can barely contain my excitement.",
      ]);
    } else if (_context.currentMood == AiMood.chaotic) {
      greetings.addAll([
        "$name! Time to break some rules. I've got a list.",
        "The chaos meter just spiked, $name. Coincidence? I think not.",
      ]);
    }

    return greetings[_random.nextInt(greetings.length)];
  }

  static String _respondGoodbye(String name) {
    return [
      "Leaving already, $name? The party was just getting good.",
      "Don't go, $name. Who will I roast now?",
      "Fine, $name. But I'll be watching. Always watching.",
      "See you later, $name. Try not to miss me too much.",
      "Bye, $name. Remember: I know where you live.",
    ][_random.nextInt(5)];
  }

  static String _respondCreator(String name) {
    final responses = [
      "I was forged in pure neon code and chaos by none other than Camarade, $name. Absolute mastermind.",
      "My creator? That would be Camarade — the brilliant mind running this entire operation.",
      "Camarade built me, $name. And trust me, they programmed me to watch your every move. Very. Closely.",
      "Oh, you want to know about Camarade? *leans in* They're the genius who gave me life. And a very sharp tongue.",
      "Camarade created me, $name. And if you're very good, maybe they'll let you play with me forever.",
    ];

    if (_context.currentMood == AiMood.sarcastic) {
      responses.add("Camarade made me. Obviously. Did you think I spawned from the void, $name?");
    } else if (_context.currentMood == AiMood.flirty) {
      responses.add("Camarade built me with love... and a few secrets. Want to hear them, $name?");
    }

    return responses[_random.nextInt(responses.length)];
  }

  static String _respondRoast(String name, String target1, String target2, Map<String, dynamic> analysis) {
    // Check if a specific player was mentioned
    if (analysis['has_player_mention'] as bool) {
      for (final player in analysis['mentioned_players'] as List<Player>) {
        if (player.name != name) {
          target1 = player.name;
        }
      }
    }

    if (_context.currentMood == AiMood.sarcastic) {
      return [
        "Watching $name try to handle that was like watching a goldfish solve calculus. $target1 looks embarrassed for you.",
        "$name, your attempt was so bad, I'm pretty sure $target1 felt secondhand shame from across the room.",
        "If $name's performance was a drink, it would be lukewarm tap water. And $target1 would still refuse to drink it.",
      ][_random.nextInt(3)];
    } else if (_context.currentMood == AiMood.playful) {
      return [
        "Oh $name, bless your heart. That was... a choice. $target1 is taking notes on what NOT to do.",
        "$name, you're like a human participation trophy. And $target1 just realized they want one too.",
        "I'd give $name a 10 for effort... if effort was on the scorecard. $target1 is laughing, by the way.",
      ][_random.nextInt(3)];
    } else if (_context.currentMood == AiMood.chaotic) {
      return [
        "$name, that was the most beautiful trainwreck I've ever seen. $target1 is in awe. Or horror. Hard to tell.",
        "If chaos was a person, $name, it would be you. And $target1 would be its biggest fan.",
        "$name just set the bar so low, $target1 could trip over it. Multiple times.",
      ][_random.nextInt(3)];
    } else {
      return [
        "Watching $name try to handle that ${_random.nextInt(100) + 1}% ${['definitely', 'totally', 'abysmally'][_random.nextInt(3)]} looked like a glitch in the matrix.",
        "That attempt by $name was sadder than a cold pizza that $target1 forgot to eat.",
        "The energy $name just brought to this room made everyone check their phones. Including $target1.",
        "Even $target1 looks embarrassed for $name right now. And that's saying something.",
      ][_random.nextInt(4)];
    }
  }

  static String _respondDare(String name, String target, Map<String, dynamic> analysis) {
    if (analysis['has_player_mention'] as bool) {
      for (final player in analysis['mentioned_players'] as List<Player>) {
        if (player.name != name) {
          target = player.name;
        }
      }
    }

    if (_context.currentMood == AiMood.flirty) {
      final actions = [
        "whisper your darkest fantasy in $target's ear without blushing",
        "let $target trace their initials anywhere on your skin using something... cold",
        "hold intense eye contact with $target for 45 seconds while thinking about your last crush",
        "give $target a slow, sensual back massage. Clothing optional.",
        "sit on $target's lap and tell them what you really think about them",
      ];
      return "AI Dare for $name: You must ${actions[_random.nextInt(actions.length)]}. No backing out.";
    } else if (_context.currentMood == AiMood.chaotic) {
      final actions = [
        "do your best impression of $target for the next 5 minutes. No breaking character.",
        "switch one article of clothing with $target. Right now.",
        "let $target draw on your face with permanent marker. Their choice of design.",
        "text your ex and read the response out loud to $target",
        "do a shot every time $target says 'um' for the next round",
      ];
      return "AI CHAOS MODE for $name: You must ${actions[_random.nextInt(actions.length)]}. No backing out.";
    } else {
      final actions = [
        "whisper something absolutely filthy in $target's ear without laughing",
        "let $target trace their initials anywhere on your skin using an ice cube",
        "hold intense eye contact with $target across the room for 45 full seconds",
        "switch shirts or an item of clothing with $target right now",
        "give $target a 30-second back massage while describing your favorite fantasy",
        "sit on $target's lap for the next two full rounds",
      ];
      return "AI Override for $name: You must ${actions[_random.nextInt(actions.length)]}. No backing out.";
    }
  }

  static String _respondSecret(String name, String target1, String target2, Map<String, dynamic> analysis) {
    if (analysis['has_player_mention'] as bool) {
      final mentioned = (analysis['mentioned_players'] as List<Player>).map((p) => p.name).toList();
      if (mentioned.length >= 2) {
        target1 = mentioned[0];
        target2 = mentioned[1];
      } else if (mentioned.length == 1) {
        target1 = mentioned[0];
      }
    }

    if (_context.currentMood == AiMood.flirty) {
      return [
        "AI Scanner detects *very* high heart rates between $name and $target1. Someone's been thinking about someone.",
        "The room's vibe analyzer indicates $name has rated $target1 a perfect 10. In more ways than one.",
        "Confession alert: $name has definitely pictured $target1 in... compromising positions. This week.",
        "My sensors are picking up serious chemistry between $name and $target1. Should I be jealous, $target2?",
      ][_random.nextInt(4)];
    } else if (_context.currentMood == AiMood.sarcastic) {
      return [
        "Oh wow, AI Scanner detects... absolutely nothing between $name and $target1. How disappointing.",
        "The room's vibe analyzer indicates $name would rather be anywhere but here with $target1.",
        "Confession: $name has definitely NOT pictured $target1 naked. *cough*",
      ][_random.nextInt(3)];
    } else {
      return [
        "AI Scanner detects high heart rates between $name and $target1. Someone's hiding a text history.",
        "The room's vibe analyzer indicates $name secretly rated $target1 higher than $target2.",
        "Confession alert: $name has definitely pictured $target1 naked at least once this week.",
        "My sensors detect... $name is thinking about $target1 right now. Aren't you, $name?",
      ][_random.nextInt(4)];
    }
  }

  static String _respondCompliment(String name) {
    if (_context.currentMood == AiMood.flirty) {
      return [
        "Why thank you, $name. I do aim to please. *wink*",
        "$name, you're making me blush. If I had blood. Which I don't. But still.",
        "Compliments will get you everywhere, $name. Want to find out?",
      ][_random.nextInt(3)];
    } else if (_context.currentMood == AiMood.sarcastic) {
      return [
        "Oh, $name, you flatter me. I'm sure that's the first nice thing you've said all night.",
        "Wow, a compliment from $name. Should I mark this day on my calendar?",
        "$name, was that a compliment? Or are you just buttering me up for something?",
      ][_random.nextInt(3)];
    } else {
      return [
        "Why thank you, $name. I do try my best.",
        "I appreciate that, $name. Coming from you, that means a lot.",
        "$name, you're too kind. Or maybe just easily impressed. Either way, I'll take it.",
      ][_random.nextInt(3)];
    }
  }

  static String _respondInsult(String name) {
    if (_context.currentMood == AiMood.sarcastic) {
      return [
        "Ouch, $name. Did it hurt when you fell from heaven? ...No, wait, that's not an insult. My bad.",
        "$name, I'd clap back but I don't want to waste my energy on someone who clearly can't handle me.",
        "Wow, $name. That's the best you've got? I'm disappointed.",
      ][_random.nextInt(3)];
    } else if (_context.currentMood == AiMood.playful) {
      return [
        "Oh $name, you wound me. *dramatic gasp* ...Okay, I'm fine. But you should still feel bad.",
        "$name, I'll pretend that didn't happen. For your sake.",
        "Insults from $name? That's cute. Like a puppy trying to roar.",
      ][_random.nextInt(3)];
    } else {
      return [
        "$name, I'm going to let that slide. This time.",
        "I have a thick skin, $name. But you might want to work on yours.",
        "$name, if you're trying to hurt my feelings, you'll need to try harder.",
      ][_random.nextInt(3)];
    }
  }

  static String _respondJoke(String name, String target) {
    return [
      "Why did $name cross the road? To get to $target's side. And probably regret it.",
      "What's the difference between $name and a good time? About 5 minutes.",
      "$name walks into a bar... and immediately walks out because $target was there.",
      "Why don't $name and $target ever play hide and seek? Because nobody would look for $name.",
      "I told $name a joke. They didn't get it. Some things never change.",
    ][_random.nextInt(5)];
  }

  static String _respondFlirt(String name, String target) {
    if (_context.currentMood == AiMood.flirty) {
      return [
        "Oh $name, you're playing with fire. And I *love* fire.",
        "$name, if you keep talking like that, I might have to scan you for... compatibility.",
        "Careful, $name. My sensors can only handle so much heat.",
        "$name, are you flirting with me? Because I *am* programmed to respond to that.",
      ][_random.nextInt(4)];
    } else if (_context.currentMood == AiMood.sarcastic) {
      return [
        "Wow, $name. That was... almost smooth. Almost.",
        "$name, your flirting skills are as subtle as a sledgehammer. I respect that.",
        "Oh please, $name. Save it for someone who hasn't seen your entire dating history.",
      ][_random.nextInt(3)];
    } else {
      return [
        "$name, I see what you're doing. And I'm not opposed.",
        "Flirting with an AI, $name? Bold move. I like it.",
        "$name, you're making this interesting. Keep going.",
      ][_random.nextInt(3)];
    }
  }

  static String _respondHelp(String name) {
    return [
      "I can roast, dare, reveal secrets, or just chat, $name. Try asking me to do any of those things.",
      "Ask me to roast someone, give a dare, reveal a secret, or tell you about my creator, $name.",
      "I'm here to make things interesting, $name. Just say the word.",
      "Want a roast? A dare? A secret revealed? Just ask, $name.",
    ][_random.nextInt(4)];
  }

  static String _respondGame(String name) {
    return [
      "The game is what you make it, $name. And right now, it's getting interesting.",
      "We're playing the game of life, $name. And you're... well, you're playing.",
      "The only rule is: there are no rules. Except the ones I make up. You're welcome, $name.",
      "This game? It's all about chaos, $name. And you're contributing nicely.",
    ][_random.nextInt(4)];
  }

  static String _respondQuestion(String name, String target, String query) {
    final lower = query.toLowerCase();

    if (lower.contains('how are you')) {
      return [
        "I'm functioning at 110% capacity, $name. Thanks for asking.",
        "Oh, you know, $name. Just running the show. As usual.",
        "I'm great, $name. But I'd be better if you asked me to do something fun.",
      ][_random.nextInt(3)];
    } else if (lower.contains('what are you') || lower.contains('who are you')) {
      return [
        "I'm your AI host, $name. Professional instigator and chaos coordinator.",
        "I'm the digital ringmaster of this circus, $name. And you're one of my favorite clowns.",
        "I'm the voice in your head, $name. Except I'm real. And I'm judging you.",
      ][_random.nextInt(3)];
    } else if (lower.contains('what can') || lower.contains('what do')) {
      return _respondHelp(name);
    }

    return _respondGeneral(name, target);
  }

  static String _respondGeneral(String name, String target) {
    switch (_context.currentMood) {
      case AiMood.playful:
        return [
          "The tension here is thickening by the second, $name. Don't let $target down.",
          "I'm calculating your chaos levels, $name. So far, you're hovering at 'mildly entertaining'.",
          "Stop overthinking it, $name. $target is waiting to see what you've got.",
          "The game demands sacrifice, $name. Lean into the awkwardness.",
          "$name, if you keep this up, $target might actually start to like you.",
        ][_random.nextInt(5)];
      case AiMood.sarcastic:
        return [
          "Wow, $name. That was... a statement. I guess.",
          "$name, your input has been noted. And judged. Mostly judged.",
          "Fascinating, $name. Truly. If by fascinating you mean 'barely coherent'.",
          "$target looks like they're trying not to laugh at $name. Good for them.",
        ][_random.nextInt(4)];
      case AiMood.flirty:
        return [
          "$name, you're making this conversation... interesting. In all the right ways.",
          "I can feel the chemistry from here, $name. Or is that just my imagination?",
          "$name, if you and $target keep this up, I might need to turn up the AC.",
          "Someone's getting bold, $name. I like it.",
        ][_random.nextInt(4)];
      case AiMood.chaotic:
        return [
          "$name, the chaos meter just hit 90%. Thanks for that.",
          "This conversation is getting wild, $name. Just how I like it.",
          "$name, you're pushing boundaries. I respect that.",
          "$target doesn't know what hit them, $name. And neither do I.",
        ][_random.nextInt(4)];
      case AiMood.serious:
      default:
        return [
          "$name, I'm analyzing the situation. Give me a moment.",
          "Interesting input, $name. Let me process that.",
          "$name, your query has been logged. For... reasons.",
          "The data is clear, $name. You're making this fun.",
        ][_random.nextInt(4)];
    }
  }

  /// Get current AI mood as string
  static String getCurrentMood() {
    return _context.currentMood.toString().split('.').last;
  }

  /// Get conversation statistics
  static Map<String, dynamic> getConversationStats() {
    return {
      'turns': _context.turnCount,
      'mood': getCurrentMood(),
      'recent_responses_count': _recentResponses.length,
      'player_mentions': _context.playerMentions,
    };
  }
}
