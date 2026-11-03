import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_rules.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../services/audio_service.dart';
import '../utils/question_loader.dart';
import '../widgets/challenge_card.dart';
import '../widgets/dare_card.dart';
import '../widgets/player_spinner.dart';
import '../widgets/truth_card.dart';
import 'leaderboard_screen.dart';
import 'winner_screen.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final List<Question> questions;

  const GameScreen({super.key, required this.players, required this.questions});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  final Random _random = Random();
  final Map<String, String> _lastChosenTypePerPlayer = {};

  String _selectedType = '';
  Player? _selectedPlayer;
  Question? _currentQuestion;
  bool _showPlayerSpinner = true;
  bool _showTypeSelector = false;
  bool _showQuestion = false;
  bool _isResolvingChallenge = false;
  Timer? _challengeTimer;
  int _challengeSecondsLeft = GameRules.dareDurationSeconds;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(players: List.of(widget.players), questions: widget.questions);
    AudioService.playBackground();
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    AudioService.stopAll();
    super.dispose();
  }

  void _onPlayerSelected(Player player) {
    AudioService.playWheelSpin();
    setState(() {
      _selectedPlayer = player;
      _showPlayerSpinner = false;
      _showTypeSelector = true;
      _selectedType = '';
    });
  }

  void _selectType(String type) {
    final player = _selectedPlayer;
    if (player != null &&
        type == 'truth' &&
        _lastChosenTypePerPlayer[player.id] == 'truth') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You chose Truth last turn! You must take a Dare this time.'),
          backgroundColor: Color(0xFFFF0080),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    AudioService.playClick();
    setState(() => _selectedType = type);
  }

  void _startQuestion() {
    final player = _selectedPlayer;
    if (_selectedType.isEmpty || player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Truth or Dare.'),
          backgroundColor: Color(0xFFFF0000),
        ),
      );
      return;
    }

    final matchingQuestions = _gameState.questions
        .where((question) => question.type.toLowerCase() == _selectedType)
        .toList();
    final unusedQuestions = matchingQuestions
        .where((question) => !_gameState.usedQuestions.contains(question))
        .toList();
    final pool = unusedQuestions.isNotEmpty ? unusedQuestions : matchingQuestions;

    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions are available for this type.'),
          backgroundColor: Color(0xFFFF0000),
        ),
      );
      return;
    }

    final selected = pool[_random.nextInt(pool.length)];
    final processedText = QuestionLoader.processQuestionText(
      selected.text,
      player,
      _gameState.players,
    );

    _challengeTimer?.cancel();
    _lastChosenTypePerPlayer[player.id] = _selectedType;

    setState(() {
      _currentQuestion = selected.copyWith(text: processedText);
      _gameState = _gameState.copyWith(
        currentType: _selectedType,
        currentQuestionIndex: _gameState.questions.indexOf(selected),
        usedQuestions: [..._gameState.usedQuestions, selected],
        currentPlayerIndex: _gameState.players.indexWhere((item) => item.id == player.id),
      );
      _challengeSecondsLeft = GameRules.dareDurationSeconds;
      _showTypeSelector = false;
      _showQuestion = true;
      _isResolvingChallenge = false;
    });

    AudioService.playCardFlip();
    if (_selectedType == 'dare') _startDareTimer();
  }

  void _startDareTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _selectedPlayer == null || _currentQuestion?.type.toLowerCase() != 'dare') {
        timer.cancel();
        return;
      }

      if (_challengeSecondsLeft <= 1) {
        timer.cancel();
        _applyChallengeResult(successful: false, timedOut: true);
        return;
      }

      setState(() => _challengeSecondsLeft--);
    });
  }

  void _applyChallengeResult({required bool successful, bool timedOut = false}) {
    final player = _selectedPlayer;
    if (player == null || _currentQuestion == null || _isResolvingChallenge) return;

    _isResolvingChallenge = true;
    _challengeTimer?.cancel();
    AudioService.playClick();

    final updatedPlayer = player.copyWith(
      score: GameRules.scoreAfterChallenge(
        currentScore: player.score,
        completed: successful,
      ),
      hasCompletedTurn: true,
    );
    final updatedPlayers = [..._gameState.players];
    final playerIndex = updatedPlayers.indexWhere((item) => item.id == player.id);
    if (playerIndex == -1) {
      _isResolvingChallenge = false;
      return;
    }
    updatedPlayers[playerIndex] = updatedPlayer;

    final resultText = successful
        ? '${player.name} completed the challenge! +${GameRules.pointsForCompletion} points.'
        : timedOut
            ? '${player.name} ran out of time. -${GameRules.pointsForFailure} points.'
            : '${player.name} skipped the challenge. -${GameRules.pointsForFailure} points.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultText),
        backgroundColor: successful ? const Color(0xFF00A86B) : const Color(0xFFFF6D00),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _gameState = _gameState.copyWith(players: updatedPlayers, currentType: '');
      _selectedType = '';
      _showQuestion = false;
      _showPlayerSpinner = true;
      _selectedPlayer = null;
      _currentQuestion = null;
      _challengeSecondsLeft = GameRules.dareDurationSeconds;
      _isResolvingChallenge = false;
    });

    final roundIsComplete = updatedPlayers.isNotEmpty &&
        updatedPlayers.every((item) => item.hasCompletedTurn);
    if (roundIsComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLeaderboard(resetRoundOnContinue: true);
      });
    }
  }

  void _showLeaderboard({bool resetRoundOnContinue = false}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LeaderboardScreen(
        players: _gameState.players,
        onContinue: () {
          Navigator.of(dialogContext).pop();
          if (!resetRoundOnContinue || !mounted) return;
          setState(() {
            final resetPlayers = _gameState.players
                .map((player) => player.copyWith(hasCompletedTurn: false))
                .toList();
            _gameState = _gameState.copyWith(players: resetPlayers);
          });
        },
      ),
    );
  }

  void _endGame() {
    final winner = _gameState.getWinner();
    if (winner == null) return;

    AudioService.playWinner();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) => WinnerScreen(
          winner: winner,
          players: _gameState.players,
          onRestart: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTruthDisabled = _selectedPlayer != null &&
        _lastChosenTypePerPlayer[_selectedPlayer!.id] == 'truth';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedPlayer != null ? "${_selectedPlayer!.name}'s Turn" : 'TRUTH OR DARE',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Show leaderboard',
            icon: const Icon(Icons.leaderboard, color: Color(0xFFFFD700)),
            onPressed: () => _showLeaderboard(),
          ),
          IconButton(
            tooltip: 'End game',
            icon: const Icon(Icons.flag, color: Color(0xFFFF0000)),
            onPressed: _endGame,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF330033), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showPlayerSpinner)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SPIN THE WHEEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Who takes the next challenge?',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 25),
                      PlayerSpinner(
                        players: _gameState.players,
                        onPlayerSelected: _onPlayerSelected,
                      ),
                    ],
                  ),
                ),
              if (_showTypeSelector)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_selectedPlayer?.name}'s Turn",
                        style: TextStyle(
                          color: _getGenderColor(_selectedPlayer?.gender ?? 'Other'),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isTruthDisabled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pinkAccent),
                          ),
                          child: const Text(
                            'Truth is locked because it was chosen last turn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChoiceButton('Truth', const Color(0xFF0080FF), isTruthDisabled),
                          const SizedBox(width: 20),
                          _buildChoiceButton('Dare', const Color(0xFFFF0080), false),
                        ],
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _selectedType.isNotEmpty ? _startQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'truth'
                              ? const Color(0xFF0080FF)
                              : const Color(0xFFFF0080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showQuestion && _currentQuestion != null)
                Expanded(
                  child: _currentQuestion!.type.toLowerCase() == 'truth'
                      ? TruthCard(
                          question: _currentQuestion!,
                          onComplete: () => _applyChallengeResult(successful: true),
                          onFail: () => _applyChallengeResult(successful: false),
                        )
                      : DareCard(
                          question: _currentQuestion!,
                          countdownSeconds: _challengeSecondsLeft,
                          onComplete: () => _applyChallengeResult(successful: true),
                          onFail: () => _applyChallengeResult(successful: false),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String type, Color color, bool isDisabled) {
    final selected = _selectedType == type.toLowerCase();
    final activeColor = isDisabled ? Colors.grey : color;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !isDisabled,
      label: type,
      child: GestureDetector(
        onTap: isDisabled ? null : () => _selectType(type.toLowerCase()),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.transparent,
              border: Border.all(color: selected ? Colors.white : activeColor, width: 2.5),
              borderRadius: BorderRadius.circular(30),
              boxShadow: selected
                  ? [BoxShadow(color: activeColor.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
                  : [],
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: selected ? Colors.black : activeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getGenderColor(String gender) =>
      gender == 'Male' ? const Color(0xFF0080FF) : const Color(0xFFFF0080);
}
