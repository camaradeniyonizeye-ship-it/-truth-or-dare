import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_routes.dart';
import '../theme/app_theme.dart';
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
      if (normalized.isNotEmpty && !uniqueNames.any((saved) => saved.toLowerCase() == normalized.toLowerCase())) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a player name first.')));
      return;
    }
    if (_players.any((player) => player.name.toLowerCase() == trimmedName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$trimmedName is already in the game.')));
      return;
    }
    AudioService.playClick();
    setState(() {
      _players.add(Player(id: '${DateTime.now().microsecondsSinceEpoch}_$trimmedName', name: trimmedName, gender: gender));
      _nameController.clear();
      _frequentNames.removeWhere((saved) => saved.toLowerCase() == trimmedName.toLowerCase());
      _frequentNames.insert(0, trimmedName);
      if (_frequentNames.length > _maxFrequentPlayers) _frequentNames = _frequentNames.take(_maxFrequentPlayers).toList();
    });
    _saveFrequentPlayers();
  }

  void _removePlayer(int index) {
    AudioService.playClick();
    setState(() => _players.removeAt(index));
  }

  void _removeFrequentName(String name) {
    setState(() => _frequentNames.removeWhere((saved) => saved.toLowerCase() == name.toLowerCase()));
    _saveFrequentPlayers();
  }

  void _startGame() {
    AudioService.playClick();
    Navigator.push(
      context,
      AppRoutes.fadeUp(
        DifficultySelectionScreen(players: List.of(_players), selectedLanguage: widget.language ?? 'English'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SETUP  •  ${(widget.language ?? 'English').toUpperCase()}')),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionLabel('Build your crew'),
                      const SizedBox(height: 10),
                      Text('Who’s in\nthe room?', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36)),
                      const SizedBox(height: 9),
                      const Text('Add at least two players to get the night started.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                      const SizedBox(height: 22),
                      AppGlassPanel(
                        accent: AppColors.neonPink,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (value) => _addPlayer(value, gender: _selectedGender),
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(hintText: 'Enter a player name', prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.neonPink), counterText: '', border: InputBorder.none),
                              maxLength: 24,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('AVATAR STYLE', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                const Spacer(),
                                _genderChip('Male', Icons.person_rounded, AppColors.neonBlue),
                                const SizedBox(width: 8),
                                _genderChip('Female', Icons.person_rounded, AppColors.neonPink),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(onPressed: () => _addPlayer(_nameController.text, gender: _selectedGender), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('ADD PLAYER')),
                          ],
                        ),
                      ),
                      if (_frequentNames.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const AppSectionLabel('Quick add'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _frequentNames.map((name) => InputChip(
                            avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.neonPink),
                            label: Text(name),
                            onPressed: () => _addPlayer(name, gender: _selectedGender),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            onDeleted: () => _removeFrequentName(name),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const AppSectionLabel('The lineup'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.neonPink.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                            child: Text('${_players.length} ${_players.length == 1 ? 'PLAYER' : 'PLAYERS'}', style: const TextStyle(color: AppColors.neonPink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_players.isEmpty)
                        AppGlassPanel(
                          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.groups_2_outlined, color: AppColors.muted, size: 30),
                                SizedBox(height: 8),
                                Text('Your crew will show up here', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._players.asMap().entries.map((entry) {
                          final index = entry.key;
                          final player = entry.value;
                          final accent = player.gender == 'Male' ? AppColors.neonBlue : AppColors.neonPink;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppGlassPanel(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                              accent: accent,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Container(width: 37, height: 37, decoration: BoxDecoration(color: accent.withOpacity(.14), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.person_rounded, color: accent, size: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700))),
                                  IconButton(tooltip: 'Remove ${player.name}', onPressed: () => _removePlayer(index), icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 20)),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(color: AppColors.background.withOpacity(.55), border: Border(top: BorderSide(color: Colors.white.withOpacity(.07)))),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _players.length >= 2 ? _startGame : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_players.length < 2 ? 'ADD ${2 - _players.length} MORE PLAYER${_players.length == 1 ? '' : 'S'}' : 'CHOOSE YOUR INTENSITY'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String gender, IconData icon, Color color) {
    final selected = _selectedGender == gender;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: selected ? color.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color.withOpacity(.55) : AppColors.outline)),
        child: Row(
          children: [
            Icon(icon, size: 15, color: selected ? color : AppColors.muted),
            const SizedBox(width: 5),
            Text(gender, style: TextStyle(color: selected ? color : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
