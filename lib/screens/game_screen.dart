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
    });
  }

  void _selectType(String type) {
    AudioService.playClick();
    setState(() => _selectedType = type);
  }

  void _startQuestion() {
    if (_selectedType.isEmpty || _selectedPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Truth or Dare!'), backgroundColor: Color(0xFFFF0000)),
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
        const SnackBar(content: Text('No questions available!'), backgroundColor: Color(0xFFFF0000)),
      );
      return;
    }

    final selected = pool[DateTime.now().millisecondsSinceEpoch % pool.length];
    final processedText = QuestionLoader.processQuestionText(
        selected.text, _selectedPlayer, widget.players);

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
    
    // Fixed: added .toInt() to ensure score addition handles num-to-int correctly
    final updatedPlayer = _selectedPlayer!.copyWith(
      score: _selectedPlayer!.score + (_currentQuestion!.difficulty.levelValue * 10).toInt(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPlayer != null
            ? "${_selectedPlayer!.name}'s Turn"
            : 'TRUTH OR DARE'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showPlayerSpinner)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('SELECT A PLAYER',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text('Choose:',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton('Truth', const Color(0xFF0080FF)),
                        const SizedBox(width: 20),
                        _buildButton('Dare', const Color(0xFFFF0080)),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _startQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType.isNotEmpty
                            ? (_selectedType == 'truth'
                                ? const Color(0xFF0080FF)
                                : const Color(0xFFFF0080))
                            : Colors.grey,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                      ),
                      child: const Text('CONTINUE',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildButton(String type, Color color) {
    final selected = _selectedType == type.toLowerCase();
    return GestureDetector(
      onTap: () => _selectType(type.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: selected ? Colors.white : color, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : color,
          ),
        ),
      ),
    );
  }

  Color _getGenderColor(String g) =>
      g == 'Male' ? const Color(0xFF0080FF) : const Color(0xFFFF0080);
}
