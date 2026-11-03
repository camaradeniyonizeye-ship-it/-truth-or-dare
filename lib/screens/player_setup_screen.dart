import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';
import '../services/audio_service.dart';
import 'difficulty_selection_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final String? language;

  const PlayerSetupScreen({super.key, this.language});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  static const int _maxFrequentPlayers = 8;

  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Male';
  List<String> _frequentNames = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    final savedNames = preferences.getStringList('frequent_players') ?? [];
    if (!mounted) return;

    final uniqueNames = <String>[];
    for (final name in savedNames) {
      final normalized = name.trim();
      if (normalized.isNotEmpty &&
          !uniqueNames.any((saved) => saved.toLowerCase() == normalized.toLowerCase())) {
        uniqueNames.add(normalized);
      }
    }
    setState(() => _frequentNames = uniqueNames.take(_maxFrequentPlayers).toList());
  }

  Future<void> _saveFrequentPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('frequent_players', _frequentNames);
  }

  void _addPlayer(String name, {required String gender}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a player name first.')),
      );
      return;
    }

    final alreadyInRoster = _players.any(
      (player) => player.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyInRoster) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$trimmedName is already in the game.')),
      );
      return;
    }

    setState(() {
      _players.add(Player(
        id: '${DateTime.now().microsecondsSinceEpoch}_$trimmedName',
        name: trimmedName,
        gender: gender,
      ));
      _nameController.clear();

      _frequentNames.removeWhere((name) => name.toLowerCase() == trimmedName.toLowerCase());
      _frequentNames.insert(0, trimmedName);
      if (_frequentNames.length > _maxFrequentPlayers) {
        _frequentNames = _frequentNames.take(_maxFrequentPlayers).toList();
      }
    });
    _saveFrequentPlayers();
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  void _removeFrequentName(String name) {
    setState(() {
      _frequentNames.removeWhere(
        (savedName) => savedName.toLowerCase() == name.toLowerCase(),
      );
    });
    _saveFrequentPlayers();
  }

  void _startGame() {
    AudioService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DifficultySelectionScreen(
          players: List.of(_players),
          selectedLanguage: widget.language ?? 'English',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Players (${widget.language ?? "English"})')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _addPlayer(value, gender: _selectedGender),
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
                      onSelected: (_) => setState(() => _selectedGender = 'Male'),
                    ),
                    const SizedBox(width: 15),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: _selectedGender == 'Female',
                      onSelected: (_) => setState(() => _selectedGender = 'Female'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _addPlayer(_nameController.text, gender: _selectedGender),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Player'),
                ),
                if (_frequentNames.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Frequent Players',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _frequentNames.map((name) => InputChip(
                      label: Text(name),
                      onPressed: () => _addPlayer(name, gender: _selectedGender),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeFrequentName(name),
                      backgroundColor: Colors.purple.withOpacity(0.2),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Players (${_players.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (_players.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Add at least two players to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      return Card(
                        color: Colors.white12,
                        child: ListTile(
                          title: Text(player.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Gender: ${player.gender}', style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            tooltip: 'Remove ${player.name}',
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removePlayer(index),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0080),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _players.length >= 2 ? _startGame : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Game', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
