import 'dart:math';
import '../models/player.dart';

class AiHostService {
  static final Random _random = Random();
  static final Set<String> _recentResponses = {};

  static String getAIResponse(String query, Player? currentPlayer, List<Player> allPlayers) {
    final lower = query.toLowerCase();
    final name = currentPlayer?.name ?? 'Player';

    // Get other players for target references
    final others = allPlayers.where((p) => p.id != currentPlayer?.id).toList();
    final target1 = others.isNotEmpty ? others[_random.nextInt(others.length)].name : 'someone';
    final target2 = others.length > 1 ? others.where((p) => p.name != target1).toList()[_random.nextInt(others.length - 1)].name : target1;

    String response = '';

    // Creator check
    if (lower.contains('creator') || lower.contains('made you') || lower.contains('built you') || lower.contains('programmed you') || lower.contains('who is your maker')) {
      final creatorReplies = [
        "I was forged in pure neon code and chaos by none other than Camarade. Absolute mastermind.",
        "My creator? That would be Camarade — the brilliant mind running this entire operation.",
        "Camarade built me. And trust me, they programmed me to watch your every move very closely.",
      ];
      response = creatorReplies[_random.nextInt(creatorReplies.length)];
    } 
    else if (lower.contains('roast') || lower.contains('judge')) {
      response = _generateRoast(name, target1);
    } 
    else if (lower.contains('dare') || lower.contains('custom')) {
      response = _generateCustomDare(name, target1);
    } 
    else if (lower.contains('secret') || lower.contains('truth')) {
      response = _generateSecretScan(name, target1, target2);
    } 
    else {
      response = _generateGeneralCommentary(name, target1);
    }

    // Ensure we don't repeat the exact same response consecutively
    while (_recentResponses.contains(response) && _recentResponses.length < 20) {
      if (lower.contains('roast') || lower.contains('judge')) {
        response = _generateRoast(name, target1);
      } else if (lower.contains('dare') || lower.contains('custom')) {
        response = _generateCustomDare(name, target1);
      } else {
        response = _generateGeneralCommentary(name, target1);
      }
    }

    _recentResponses.add(response);
    if (_recentResponses.length > 15) {
      _recentResponses.remove(_recentResponses.first);
    }

    return response;
  }

  static String _generateRoast(String name, String target) {
    final subjects = [
      "Watching $name try to handle that",
      "That attempt by $name",
      "The energy $name just brought to this room",
      "Even $target looks embarrassed for $name right now",
      "If laziness was an art form",
    ];
    final verbs = [
      "looked like a glitch in the matrix.",
      "was sadder than a cold pizza.",
      "made everyone in the room check their phones.",
      "belongs in a museum of awkward moments.",
      "had all the spice of lukewarm tap water.",
    ];
    return "${subjects[_random.nextInt(subjects.length)]} ${_random.nextInt(100) + 1}% ${_random.choice(['definitely', 'totally', 'abysmally'])} ${verbs[_random.nextInt(verbs.length)]}";
  }

  static String _generateCustomDare(String name, String target) {
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

  static String _generateSecretScan(String name, String t1, String t2) {
    final scans = [
      "AI Scanner detects high heart rates between $name and $t1. Someone's hiding a text history.",
      "The room's vibe analyzer indicates $name secretly rated $t1 higher than $t2.",
      "Confession alert: $name has definitely pictured $t1 naked at least once this week.",
    ];
    return scans[_random.nextInt(scans.length)];
  }

  static String _generateGeneralCommentary(String name, String target) {
    final comments = [
      "The tension here is thickening by the second, $name. Don't let $target down.",
      "I'm calculating your chaos levels, $name. So far, you're hovering at mild.",
      "Stop overthinking it, $name. $target is waiting to see what you've got.",
      "The game demands sacrifice, $name. Lean into the awkwardness.",
    ];
    return comments[_random.nextInt(comments.length)];
  }
}

extension on List<String> {
  String choice() => this[Random().nextInt(length)];
}
