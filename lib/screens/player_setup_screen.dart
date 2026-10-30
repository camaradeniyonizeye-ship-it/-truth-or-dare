import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import 'difficulty_selection_screen.dart';
import '../services/audio_service.dart';

class PlayerSetupScreen extends StatefulWidget {
  final String? language;

  const PlayerSetupScreen({
    super.key,
    this.language,
  });

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Male';
  List<String> _frequentNames = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();
  }

  Future<void> _loadSavedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('frequent_players') ?? [];
    setState(() {
      _frequentNames = saved;
    });
  }

  Future<void> _saveFrequentPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final names = _players.map((p) => p.name).toList();
    await prefs.setStringList('frequent_players', names);
  }

  void _addPlayer(String name, {String gender = 'Male'}) {
    if (name.trim().isEmpty) return;
    setState(() {
      _players.add(Player(
        id: DateTime.now().millisecondsSinceEpoch.toString() + name,
        name: name.trim(),
        gender: gender,
      ));
      _nameController.clear();
    });
    _saveFrequentPlayers();
  }

  void _removePlayer(int index) {
    setState(() {
      _players.removeAt(index);
    });
    _saveFrequentPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Players (${widget.language ?? "English"})')),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter player name',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _selectedGender == 'Male',
                  onSelected: (val) => setState(() => _selectedGender = 'Male'),
                ),
                const SizedBox(width: 15),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _selectedGender == 'Female',
                  onSelected: (val) => setState(() => _selectedGender = 'Female'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _addPlayer(_nameController.text, gender: _selectedGender),
              child: const Text('Add Player'),
            ),
            if (_frequentNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Frequent Players:', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 8,
                children: _frequentNames.map((name) => ActionChip(
                  label: Text(name),
                  onPressed: () => _addPlayer(name, gender: 'Male'),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Players List:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return Card(
                    color: Colors.white24,
                    child: ListTile(
                      title: Text(player.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Gender: ${player.gender}', style: const TextStyle(color: Colors.white70)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _removePlayer(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: _players.length >= 2
                  ? () {
                      AudioService.playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DifficultySelectionScreen(
                            players: _players,
                            selectedLanguage: widget.language ?? 'English',
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Start Game', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
