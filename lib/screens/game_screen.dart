import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import '../models/player.dart';
import '../models/question.dart';
import '../models/game_rules.dart';
import '../utils/question_loader.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
import '../widgets/player_spinner.dart';
import '../widgets/ai_host_modal.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final List<Question> questions;

  const GameScreen({
    super.key,
    required this.players,
    required this.questions,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Player? _currentPlayer;
  Question? _currentQuestion;
  String _activeType = '';
  bool _isTurnActive = false;
  bool _isBackConfirmed = false;

  // Settings states
  String _currentThemeMode = 'Neon Cyberpunk';
  int _dareDuration = 30;
  bool _shotModeEnabled = false;

  // Timer state variables
  Timer? _dareTimer;
  int _remainingSeconds = 30;
  bool _isTimerActive = false;

  // Animation controllers
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // Initialize animations
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _cardController.forward();

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _dareTimer?.cancel();
    _cardController.dispose();
    _confettiController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    
    super.dispose();
  }

  void _startDareTimer() {
    _dareTimer?.cancel();
    setState(() {
      _remainingSeconds = _dareDuration;
      _isTimerActive = true;
    });

    _dareTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });
        HapticFeedback.heavyImpact();
        if (AudioService.sfxEnabled) AudioService.playClick();
      }
    });
  }

  void _onPlayerSelected(Player selectedPlayer) {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    setState(() {
      _currentPlayer = selectedPlayer;
      _isTurnActive = true;
      _currentQuestion = null;
      _activeType = '';
      _isTimerActive = false;
    });
    _cardController.forward(from: 0.0);
  }

  void _selectType(String type) {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();

    // Enforce Rule: Lock Truth if the player selected Truth on their previous turn
    if (type.toLowerCase() == 'truth' && _currentPlayer?.lastChosenType == 'truth') {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentPlayer?.name ?? "Player"}, you cannot pick TRUTH twice in a row! Choose DARE.'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _dareTimer?.cancel();

    final available = widget.questions.where((q) => q.type.toLowerCase() == type.toLowerCase()).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more questions in this category!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    available.shuffle();
    final rawQuestion = available.first;

    final processedText = QuestionLoader.processQuestionText(
      rawQuestion.text,
      _currentPlayer,
      widget.players,
    );

    setState(() {
      _activeType = type;
      _currentPlayer?.lastChosenType = type.toLowerCase();
      _currentQuestion = Question(
        id: rawQuestion.id,
        type: rawQuestion.type,
        text: processedText,
        category: rawQuestion.category,
      );
      _isTimerActive = false;
    });

    _cardController.forward(from: 0.0);

    if (type.toLowerCase() == 'dare') {
      _startDareTimer();
    }
  }

  void _recordChallengeResult(bool completed) {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    _dareTimer?.cancel();

    if (_currentPlayer != null) {
      final delta = completed ? GameRules.pointsForCompletion : -GameRules.pointsForFailure;
      _currentPlayer!.score = (_currentPlayer!.score + delta).clamp(0, 0x7fffffff);
      _currentPlayer!.hasCompletedTurn = true;

      // Trigger confetti for completed challenges
      if (completed) {
        _confettiController.play();
        setState(() => _showConfetti = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showConfetti = false);
        });
      }

      // If Shot Mode is enabled and challenge failed, trigger penalty dialog
      if (!completed && _shotModeEnabled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _showDrinkingPenalty();
        });
      }
    }

    final allDone = widget.players.every((p) => p.hasCompletedTurn);
    if (allDone) {
      for (var p in widget.players) {
        p.hasCompletedTurn = false;
      }
      // Optional: Show round complete message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Round Complete! Next player up...'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _currentPlayer = null;
      _isTurnActive = false;
      _currentQuestion = null;
      _activeType = '';
      _isTimerActive = false;
    });
    _cardController.forward(from: 0.0);
  }

  void _showDrinkingPenalty() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neonRed, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_bar_rounded, color: AppColors.neonRed),
            SizedBox(width: 10),
            Text(
              'DRINKING PENALTY!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '${_currentPlayer!.name} failed the challenge! Take ${_shotModeEnabled ? '2' : '1'} sip${_shotModeEnabled ? 's' : ''} immediately.',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (AudioService.sfxEnabled) AudioService.playClick();
              Navigator.pop(context);
            },
            child: const Text(
              'CHUGGED 🍻',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomPromptModal() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController();
    String selectedType = 'dare';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF140A1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.neonPink.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.neonPink,
              ),
              SizedBox(width: 10),
              Text(
                'INJECT CUSTOM PROMPT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your custom truth or dare...',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Truth'),
                      selected: selectedType == 'truth',
                      selectedColor: AppColors.neonBlue.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: selectedType == 'truth'
                            ? AppColors.neonBlue
                            : Colors.white,
                      ),
                      onSelected: (val) => setDialogState(
                        () => selectedType = 'truth',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Dare'),
                      selected: selectedType == 'dare',
                      selectedColor: AppColors.neonPink.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: selectedType == 'dare'
                            ? AppColors.neonPink
                            : Colors.white,
                      ),
                      onSelected: (val) => setDialogState(
                        () => selectedType = 'dare',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  HapticFeedback.lightImpact();
                  if (AudioService.sfxEnabled) AudioService.playClick();
                  
                  widget.questions.add(Question(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    type: selectedType,
                    text: textController.text.trim(),
                    category: 'Custom',
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom prompt injected!'),
                      backgroundColor: AppColors.neonPink,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                'INJECT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaderboard() {
    HapticFeedback.lightImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    
    final sortedPlayers = List<Player>.from(widget.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.neonPink.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.leaderboard_rounded, color: AppColors.neonPink),
            SizedBox(width: 10),
            Text(
              'SCOREBOARD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final isLeader = index == 0;
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isLeader
                      ? AppColors.neonPink.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLeader
                        ? AppColors.neonPink
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: isLeader
                            ? AppColors.neonPink
                            : AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${player.score} PTS',
                      style: TextStyle(
                        color: isLeader
                            ? AppColors.neonPink
                            : AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                color: AppColors.neonPink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    HapticFeedback.lightImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF140A1F),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: AppColors.neonPink.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    color: AppColors.neonPink,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'GAME SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // SFX Toggle
              SwitchListTile(
                title: const Text(
                  'Sound Effects (SFX)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Play clicks and completion alerts',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                value: AudioService.sfxEnabled,
                activeColor: AppColors.neonPink,
                onChanged: (val) async {
                  HapticFeedback.selectionClick();
                  await AudioService.setSfxEnabled(val);
                  setModalState(() {});
                  setState(() {});
                },
              ),
              
              // Music Toggle
              SwitchListTile(
                title: const Text(
                  'Background Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Ambient atmospheric tunes',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                value: AudioService.musicEnabled,
                activeColor: AppColors.neonPink,
                onChanged: (val) async {
                  HapticFeedback.selectionClick();
                  await AudioService.setMusicEnabled(val);
                  setModalState(() {});
                  setState(() {});
                },
              ),
              
              // Shot Mode Toggle
              SwitchListTile(
                title: const Text(
                  '18+ Shot / Drinking Mode 🍻',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Triggers drinking penalties on failed dares',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                value: _shotModeEnabled,
                activeColor: AppColors.neonRed,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setModalState(() => _shotModeEnabled = val);
                  setState(() {});
                },
              ),
              
              const Divider(
                color: Colors.white24,
                height: 24,
              ),
              
              // Theme Selection
              const Text(
                'Theme Vibe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Neon Cyberpunk'),
                      selected: _currentThemeMode == 'Neon Cyberpunk',
                      selectedColor: AppColors.neonPink.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _currentThemeMode == 'Neon Cyberpunk'
                            ? AppColors.neonPink
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setModalState(
                          () => _currentThemeMode = 'Neon Cyberpunk',
                        );
                        AppColors.setThemeMode('Neon Cyberpunk');
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Midnight Velvet'),
                      selected: _currentThemeMode == 'Midnight Velvet',
                      selectedColor: AppColors.neonBlue.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _currentThemeMode == 'Midnight Velvet'
                            ? AppColors.neonBlue
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setModalState(
                          () => _currentThemeMode = 'Midnight Velvet',
                        );
                        AppColors.setThemeMode('Midnight Velvet');
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Timer Duration
              const Text(
                'Dare Timer Duration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('15s Quick'),
                      selected: _dareDuration == 15,
                      selectedColor: AppColors.neonPink.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _dareDuration == 15
                            ? AppColors.neonPink
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setModalState(() => _dareDuration = 15);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('30s Standard'),
                      selected: _dareDuration == 30,
                      selectedColor: AppColors.neonPink.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: _dareDuration == 30
                            ? AppColors.neonPink
                            : Colors.white,
                      ),
                      onSelected: (selected) {
                        HapticFeedback.selectionClick();
                        setModalState(() => _dareDuration = 30);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'SAVE SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerAccent = _currentPlayer != null &&
            _currentPlayer!.gender.toLowerCase() == 'male'
        ? AppColors.neonBlue
        : AppColors.neonPink;

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
          title: Text(
            _currentPlayer == null
                ? 'SPIN FOR YOUR FATE'
                : '${_currentPlayer!.name.toUpperCase()}\'S TURN',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.neonPink,
              ),
              tooltip: 'Add Custom Prompt',
              onPressed: _showAddCustomPromptModal,
            ),
            IconButton(
              icon: const Icon(
                Icons.leaderboard_rounded,
                color: AppColors.neonPink,
              ),
              tooltip: 'View Leaderboard',
              onPressed: _showLeaderboard,
            ),
            IconButton(
              icon: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.neonPink,
              ),
              tooltip: 'Ask AI Host',
              onPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AiHostModal(
                    currentPlayer: _currentPlayer,
                    allPlayers: widget.players,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                color: AppColors.muted,
              ),
              tooltip: 'Game Settings',
              onPressed: _showSettings,
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _dareTimer?.cancel();
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            AppBackground(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // --- TOP STATUS SECTION ---
                              if (_currentPlayer != null)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Row(
                                    key: ValueKey<String>(
                                      '${_currentPlayer!.id}_status',
                                    ),
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: playerAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: playerAccent.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              size: 16,
                                              color: playerAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _currentPlayer!.name,
                                              style: TextStyle(
                                                color: playerAccent,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Score: ${_currentPlayer!.score}',
                                          style: TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox(height: 8),

                              // --- CENTER SPINNER / CARD SECTION ---
                              Center(
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.0, 0.08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                    child: !_isTurnStatusActive()
                                        ? PlayerSpinner(
                                            players: widget.players,
                                            onPlayerSelected: _onPlayerSelected,
                                          )
                                        : (_currentQuestion == null
                                            ? _buildChoiceSelectorCard()
                                            : _buildChallengeCard()),
                                  ),
                                ),
                              ),

                              // --- CONFETTI (for completed challenges) ---
                              if (_showConfetti)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: ConfettiWidget(
                                    confettiController: _confettiController,
                                    blastDirectionality:
                                        BlastDirectionality.explosive,
                                    shouldLoop: false,
                                    colors: const [
                                      Colors.red,
                                      Colors.pink,
                                      Colors.orange,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.white,
                                      AppColors.gold,
                                    ],
                                    emissionFrequency: 0.8,
                                    numberOfParticles: 25,
                                    maxBlastForce: 120,
                                    minBlastForce: 80,
                                    gravity: 0.3,
                                  ),
                                ),

                              // --- BOTTOM ACTION BUTTONS ---
                              if (_currentQuestion != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors
                                                  .neonRed
                                                  .withOpacity(0.2),
                                              side: const BorderSide(
                                                color: AppColors.neonRed,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _recordChallengeResult(false),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: AppColors.neonRed,
                                            ),
                                            label: Text(
                                              'FAILED (-${GameRules.pointsForFailure})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.neonRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors
                                                  .neonGreen
                                                  .withOpacity(0.2),
                                              side: const BorderSide(
                                                color: AppColors.neonGreen,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _recordChallengeResult(true),
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              color: AppColors.neonGreen,
                                            ),
                                            label: Text(
                                              'COMPLETED (+${GameRules.pointsForCompletion})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.neonGreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTurnStatusActive() {
    return _isTurnActive && _currentPlayer != null;
  }

  Widget _buildChoiceSelectorCard() {
    final bool isTruthDisabled = _currentPlayer?.lastChosenType == 'truth';

    return AppGlassPanel(
      key: const ValueKey('selector'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE YOUR FATE',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              key: ValueKey<bool>(isTruthDisabled),
              isTruthDisabled
                  ? '${_currentPlayer?.name}, you picked Truth last turn. DARE is required!'
                  : '${_currentPlayer?.name ?? "Player"}, truth or dare?',
              style: TextStyle(
                color: isTruthDisabled ? AppColors.neonRed : AppColors.muted,
                fontSize: 13,
                fontWeight: isTruthDisabled ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              // --- TRUTH BUTTON ---
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isTruthDisabled
                          ? Colors.white10
                          : AppColors.neonBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isTruthDisabled
                            ? Colors.white24
                            : AppColors.neonBlue,
                        width: 1.5,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isTruthDisabled ? null : () => _selectType('truth'),
                      child: Text(
                        isTruthDisabled ? 'LOCKED 🔒' : 'TRUTH',
                        style: TextStyle(
                          color: isTruthDisabled
                              ? AppColors.muted
                              : AppColors.neonBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // --- DARE BUTTON ---
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.neonPink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: const Border.all(
                        color: AppColors.neonPink,
                        width: 1.5,
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _selectType('dare'),
                      child: const Text(
                        'DARE',
                        style: TextStyle(
                          color: AppColors.neonPink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    final isTruth = _activeType.toLowerCase() == 'truth';
    final accentColor = isTruth ? AppColors.neonBlue : AppColors.neonPink;

    String timerStatusText = '';
    if (!isTruth && _isTimerActive) {
      if (_remainingSeconds > (_dareDuration / 2)) {
        timerStatusText =
            '📖 READING & PREPARING (${_remainingSeconds - (_dareDuration ~/ 2)}s)';
      } else {
        timerStatusText = '⚡ ACTION TIME! (${_remainingSeconds}s remaining)';
      }
    } else if (!isTruth && !_isTimerActive && _remainingSeconds == 0) {
      timerStatusText = '⏰ TIME IS UP!';
    }

    return AppGlassPanel(
      key: const ValueKey('challenge'),
      accent: accentColor,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeType.toUpperCase(),
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currentQuestion!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isTruth) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / _dareDuration.toDouble(),
                    strokeWidth: 3,
                    color: accentColor,
                    backgroundColor: Colors.white12,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    key: ValueKey<int>(_remainingSeconds),
                    timerStatusText,
                    style: TextStyle(
                      color: _remainingSeconds <= 5 && _isTimerActive
                          ? AppColors.neonRed
                          : accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
