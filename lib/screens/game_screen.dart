import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../models/game_state.dart';
import '../widgets/truth_card.dart';
import '../widgets/dare_card.dart';
import '../widgets/player_spinner.dart';
import 'leaderboard_screen.dart';
import 'winner_screen.dart';
import '../services/audio_service.dart';
import '../utils/question_loader.dart';

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final List<Question> questions;

  const GameScreen({super.key, required this.players, required this.questions});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  String _selectedType = '';
  Player? _selectedPlayer;
  bool _showPlayerSpinner = true;
  bool _showTypeSelector = false;
  bool _showQuestion = false;
  Question? _currentQuestion;

  final Map<String, String> _lastChosenTypePerPlayer = {};

  @override
  void initState() {
    super.initState();
    _gameState = GameState(players: widget.players, questions: widget.questions);
    AudioService.playBackground();
  }

  @override
  void dispose() {
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
    if (_selectedPlayer != null &&
        type.toLowerCase() == 'truth' &&
        _lastChosenTypePerPlayer[_selectedPlayer!.id] == 'truth') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You chose Truth last turn! You must take a DARE this time!'),
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
    if (_selectedType.isEmpty || _selectedPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Truth or Dare!'),
          backgroundColor: Color(0xFFFF0000),
        ),
      );
      return;
    }

    final available = _gameState.questions
        .where((q) => q.type == _selectedType && !_gameState.usedQuestions.contains(q))
        .toList();

    final pool = available.isNotEmpty
        ? available
        : _gameState.questions.where((q) => q.type == _selectedType).toList();

    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions available for this category!'),
          backgroundColor: Color(0xFFFF0000),
        ),
      );
      return;
    }

    final selected = pool[DateTime.now().millisecondsSinceEpoch % pool.length];
    final processedText = QuestionLoader.processQuestionText(
        selected.text, _selectedPlayer, widget.players);

    _lastChosenTypePerPlayer[_selectedPlayer!.id] = _selectedType.toLowerCase();

    setState(() {
      _currentQuestion = selected.copyWith(text: processedText);
      _gameState = _gameState.copyWith(
        currentType: _selectedType,
        currentQuestionIndex: widget.questions.indexOf(selected),
        usedQuestions: [..._gameState.usedQuestions, selected],
        currentPlayerIndex: widget.players.indexOf(_selectedPlayer!),
      );
      _showTypeSelector = false;
      _showQuestion = true;
      AudioService.playCardFlip();
    });
  }

  void _completeQuestion() {
    AudioService.playClick();
    if (_selectedPlayer == null || _currentQuestion == null) return;

    final updatedPlayer = _selectedPlayer!.copyWith(
      score: _selectedPlayer!.score + 10,
      hasCompletedTurn: true,
    );

    final updatedPlayers = [..._gameState.players];
    final idx = _gameState.players.indexWhere((p) => p.id == _selectedPlayer!.id);
    if (idx != -1) updatedPlayers[idx] = updatedPlayer;

    setState(() {
      _gameState = _gameState.copyWith(players: updatedPlayers, currentType: '');
      _selectedType = '';
      _showQuestion = false;
      _showPlayerSpinner = true;
      _selectedPlayer = null;
      _currentQuestion = null;
    });

    if (updatedPlayers.every((p) => p.hasCompletedTurn) && updatedPlayers.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLeaderboard());
    }
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          height: 500,
          child: LeaderboardScreen(
            players: _gameState.players,
            onContinue: () {
              Navigator.pop(context);
              setState(() {
                final reset = _gameState.players
                    .map((p) => p.copyWith(hasCompletedTurn: false))
                    .toList();
                _gameState = _gameState.copyWith(players: reset);
              });
            },
          ),
        ),
      ),
    );
  }

  void _endGame() {
    AudioService.playWinner();
    final winner = _gameState.getWinner();
    if (winner == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
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
    final bool isTruthDisabled = _selectedPlayer != null &&
        _lastChosenTypePerPlayer[_selectedPlayer!.id] == 'truth';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedPlayer != null
              ? "${_selectedPlayer!.name}'s Turn"
              : 'TRUTH OR DARE',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Color(0xFFFFD700)),
            onPressed: _showLeaderboard,
          ),
          IconButton(
            icon: const Icon(Icons.flag, color: Color(0xFFFF0000)),
            onPressed: _endGame,
          )
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
                            '⚠️ TRUTH locked! You picked Truth last turn.',
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
                        onPressed: _startQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType.isNotEmpty
                              ? (_selectedType == 'truth'
                                  ? const Color(0xFF0080FF)
                                  : const Color(0xFFFF0080))
                              : Colors.grey,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      )
                    ],
                  ),
                ),
              if (_showQuestion && _currentQuestion != null && _selectedPlayer != null)
                Expanded(
                  child: _currentQuestion!.type == 'truth'
                      ? TruthCard(
                          question: _currentQuestion!,
                          player: _selectedPlayer!,
                          onComplete: _completeQuestion,
                        )
                      : DareCard(
                          question: _currentQuestion!,
                          player: _selectedPlayer!,
                          onComplete: _completeQuestion,
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

    return GestureDetector(
      onTap: () => _selectType(type.toLowerCase()),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
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
    );
  }

  Color _getGenderColor(String g) =>
      g == 'Male' ? const Color(0xFF0080FF) : const Color(0xFFFF0080);
}
