import 'package:flutter/material.dart';
import '../models/player.dart';
import 'difficulty_selection_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final List<Player> players;
  final Function(List<Player>) onPlayersAdded;

  const PlayerSetupScreen({
    super.key,
    required this.players,
    required this.onPlayersAdded,
  });

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedLanguage = 'English';

  final List<String> _languages = ['English', 'French', 'Kinyarwanda', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _players.addAll(widget.players);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _players.add(Player(
        id: DateTime.now().millisecondsSinceEpoch.toString() + _players.length.toString(),
        name: _nameController.text.trim(),
        gender: _selectedGender,
      ));
      _nameController.clear();
    });
  }

  void _removePlayer(String id) =>
      setState(() => _players.removeWhere((p) => p.id == id));

  void _proceedToGame() {
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 players for endless party fun!'),
          backgroundColor: Color(0xFFFF0000),
        ),
      );
      return;
    }
    widget.onPlayersAdded(_players);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DifficultySelectionScreen(
          players: _players,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENDLESS PLAYERS & LANGUAGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFFFF0080)),
            onPressed: _proceedToGame,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Game Language:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      underline: const SizedBox(),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Text(lang),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Player Name (Endless Input)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF0080)),
                        ),
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Male', 'Female', 'Other']
                          .map((g) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: _selectedGender == g,
                                  onSelected: (s) =>
                                      setState(() => _selectedGender = g),
                                  selectedColor: const Color(0xFFFF0080),
                                  labelStyle: TextStyle(
                                    color: _selectedGender == g
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addPlayer,
                      icon: const Icon(Icons.person_add),
                      label: const Text('ADD PLAYER',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Players List (${_players.length})',
                    style: const TextStyle(
                        color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                if (_players.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _players.clear()),
                    child: const Text('Clear All',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (ctx, i) {
                  final p = _players[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.gender == 'Male'
                            ? const Color(0xFF0080FF)
                            : p.gender == 'Female'
                                ? const Color(0xFFFF0080)
                                : Colors.purple,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Gender: ${p.gender}',
                          style: const TextStyle(color: Colors.white70)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFFF0000)),
                        onPressed: () => _removePlayer(p.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0080),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'START GAME WITH THESE PLAYERS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
