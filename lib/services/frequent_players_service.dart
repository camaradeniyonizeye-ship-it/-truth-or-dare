import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class FrequentPlayersService {
  static const String _key = 'frequent_players_v2';

  // Save a player (Name + Gender) to local storage
  static Future<void> saveFrequentPlayer(String name, String gender) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Player> current = await getFrequentPlayers();
    
    // Check if player with same name already exists
    final index = current.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    if (index >= 0) {
      // Update existing record with the updated gender
      current[index] = Player(
        id: current[index].id, 
        name: name, 
        gender: gender,
      );
    } else {
      current.add(Player(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        gender: gender,
      ));
    }

    final String rawJson = jsonEncode(current.map((p) => p.toJson()).toList());
    await prefs.setString(_key, rawJson);
  }

  // Retrieve all saved frequent players with preserved gender profiles
  static Future<List<Player>> getFrequentPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_key);
    if (rawJson == null || rawJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      return decoded.map((item) => Player.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Remove a saved player from quick-add storage
  static Future<void> removeFrequentPlayer(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Player> current = await getFrequentPlayers();
    current.removeWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    final String rawJson = jsonEncode(current.map((p) => p.toJson()).toList());
    await prefs.setString(_key, rawJson);
  }
}
