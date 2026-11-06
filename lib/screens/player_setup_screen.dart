import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int _minPlayers = 2;

  final List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Male';
  // Store both name and gender: Map<name, gender>
  Map<String, String> _frequentPlayers = {};
  bool _isBackConfirmed = false;
  bool _animatedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPlayers();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // Animate in after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animatedIn = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  Future<void> _loadSavedPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    // Load as map: name -> gender
    final savedPlayers = preferences.getStringList('frequent_players') ?? [];
    
    if (!mounted) return;
    
    final Map<String, String> loadedPlayers = {};
    for (final entry in savedPlayers) {
      // Format: "name:gender"
      final parts = entry.split(':');
      if (parts.length == 2) {
        loadedPlayers[parts[0]] = parts[1];
      }
    }
    
    setState(() => _frequentPlayers = loadedPlayers);
  }

  Future<void> _saveFrequentPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    // Save as list of "name:gender" strings
    final saveList = _frequentPlayers.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await preferences.setStringList('frequent_players', saveList);
  }

  void _addPlayer(String name, {String? gender}) {
    // Use provided gender or fallback to selected
    final playerGender = gender ?? _selectedGender;
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a player name.'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (trimmedName.length > 24) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is too long (max 24 characters).'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_players.any((player) => player.name.toLowerCase() == trimmedName.toLowerCase())) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trimmedName is already in the game.'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }

    setState(() {
      _players.add(Player(
        id: '${DateTime.now().microsecondsSinceEpoch}_$trimmedName',
        name: trimmedName,
        gender: playerGender,
      ));
      _nameController.clear();

      // Update frequent players - save with gender
      _frequentPlayers.remove(trimmedName);
      _frequentPlayers[trimmedName] = playerGender;
      // Keep only the most recent _maxFrequentPlayers
      if (_frequentPlayers.length > _maxFrequentPlayers) {
        // Remove the oldest entry (not recently added)
        final keys = _frequentPlayers.keys.toList();
        _frequentPlayers.remove(keys.last);
      }
    });

    _saveFrequentPlayers();
  }

  void _removePlayer(int index) {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }

    setState(() => _players.removeAt(index));
  }

  void _removeFrequentPlayer(String name) {
    HapticFeedback.lightImpact();
    setState(() => _frequentPlayers.remove(name));
    _saveFrequentPlayers();
  }

  void _startGame() {
    if (_players.length < _minPlayers) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add at least ${_minPlayers - _players.length} more player${_minPlayers - _players.length > 1 ? 's' : ''} to start.'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }

    Navigator.push(
      context,
      AppRoutes.fadeUp(
        DifficultySelectionScreen(
          players: List.of(_players),
          selectedLanguage: widget.language ?? 'English',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isBackConfirmed) return true;
        setState(() => _isBackConfirmed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Press back again to exit'),
            backgroundColor: AppColors.neonPink.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isBackConfirmed = false);
        });
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: AnimatedOpacity(
            opacity: _animatedIn ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Text(
              'SETUP  •  ${(widget.language ?? 'English').toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          actions: [
            if (_players.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.muted),
                tooltip: 'Clear All Players',
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF140A1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: Border.all(color: AppColors.neonRed.withOpacity(0.4)),
                      ),
                      title: const Text(
                        'CLEAR ALL PLAYERS?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'This will remove all players from the current game.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _players.clear());
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'CLEAR ALL',
                            style: TextStyle(color: AppColors.neonRed),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedOpacity(
                      opacity: _animatedIn ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          AnimatedSlide(
                            offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: const AppSectionLabel('Build your crew'),
                          ),

                          const SizedBox(height: 10),

                          AnimatedSlide(
                            offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: Text(
                              'Who\'s in\nthe room?',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 36,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 9),

                          AnimatedOpacity(
                            opacity: _animatedIn ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: const Text(
                              'Add at least two players to get the night started.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Add Player Card
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              _animatedIn ? 0 : 20,
                              0,
                            ),
                            child: AppGlassPanel(
                              accent: AppColors.neonPink,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (value) => _addPlayer(
                                      value,
                                      gender: _selectedGender,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter a player name',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.neonPink,
                                      ),
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                    maxLength: 24,
                                  ),

                                  const SizedBox(height: 10),

                                  AnimatedSlide(
                                    offset: _animatedIn ? Offset.zero : const Offset(0, 10),
                                    duration: const Duration(milliseconds: 500),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'AVATAR STYLE',
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const Spacer(),
                                        _genderChip('Male', Icons.person_rounded, AppColors.neonBlue),
                                        const SizedBox(width: 8),
                                        _genderChip('Female', Icons.person_rounded, AppColors.neonPink),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  AnimatedSlide(
                                    offset: _animatedIn ? Offset.zero : const Offset(0, 10),
                                    duration: const Duration(milliseconds: 500),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _addPlayer(
                                        _nameController.text,
                                        gender: _selectedGender,
                                      ),
                                      icon: const Icon(Icons.person_add_alt_1_rounded),
                                      label: const Text('ADD PLAYER'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quick Add Section
                          if (_frequentPlayers.isNotEmpty) ...[
                            const SizedBox(height: 22),

                            AnimatedSlide(
                              offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                              duration: const Duration(milliseconds: 500),
                              child: Row(
                                children: [
                                  const AppSectionLabel('Quick add'),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.muted,
                                      size: 18,
                                    ),
                                    tooltip: 'Refresh Frequent Players',
                                    onPressed: _loadSavedPlayers,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            AnimatedSlide(
                              offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                              duration: const Duration(milliseconds: 500),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _frequentPlayers.entries.map((entry) {
                                  final name = entry.key;
                                  final gender = entry.value;
                                  final genderColor = gender == 'Male' 
                                      ? AppColors.neonBlue 
                                      : AppColors.neonPink;
                                  
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    child: InputChip(
                                      avatar: Icon(
                                        gender == 'Male' 
                                            ? Icons.person_rounded 
                                            : Icons.person_rounded,
                                        size: 16,
                                        color: genderColor,
                                      ),
                                      label: Text(name),
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: AppColors.surfaceRaised,
                                      deleteIcon: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.muted,
                                      ),
                                      onPressed: () => _addPlayer(
                                        name,
                                        gender: gender, // Use saved gender
                                      ),
                                      onDeleted: () => _removeFrequentPlayer(name),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Player List Section
                          AnimatedSlide(
                            offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                            duration: const Duration(milliseconds: 500),
                            child: Row(
                              children: [
                                const AppSectionLabel('The lineup'),
                                const Spacer(),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _players.length >= _minPlayers
                                        ? AppColors.neonGreen.withOpacity(.12)
                                        : AppColors.neonPink.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_players.length} ${_players.length == 1 ? 'PLAYER' : 'PLAYERS'}',
                                    style: TextStyle(
                                      color: _players.length >= _minPlayers
                                          ? AppColors.neonGreen
                                          : AppColors.neonPink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Empty State or Player List
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _players.isEmpty
                                ? AppGlassPanel(
                                    key: const ValueKey<bool>(true),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 25,
                                      horizontal: 18,
                                    ),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.groups_2_outlined,
                                            color: AppColors.muted,
                                            size: 30,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Your crew will show up here',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Add players to get started',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    key: const ValueKey<bool>(false),
                                    children: _players.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final player = entry.value;
                                      final accent = player.gender == 'Male'
                                          ? AppColors.neonBlue
                                          : AppColors.neonPink;

                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        transform: Matrix4.translationValues(
                                          0,
                                          _animatedIn ? 0 : 20,
                                          0,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: AppGlassPanel(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 6,
                                            ),
                                            accent: accent,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 37,
                                                  height: 37,
                                                  decoration: BoxDecoration(
                                                    color: accent.withOpacity(.14),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    color: accent,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    player.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors.white,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Remove ${player.name}',
                                                  onPressed: () => _removePlayer(index),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: AppColors.muted,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Button
                AnimatedSlide(
                  offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(.55),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(.07)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _players.length >= _minPlayers ? _startGame : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _players.length < _minPlayers
                              ? 'ADD ${_minPlayers - _players.length} MORE PLAYER${_minPlayers - _players.length > 1 ? 'S' : ''}'
                              : 'CHOOSE YOUR INTENSITY',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String gender, IconData icon, Color color) {
    final selected = _selectedGender == gender;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedGender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withOpacity(.55) : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? color : AppColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              gender,
              style: TextStyle(
                color: selected ? color : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
