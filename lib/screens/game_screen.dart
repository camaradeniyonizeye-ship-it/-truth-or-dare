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
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
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
  void initState() { super.initState(); _gameState = GameState(players: List.of(widget.players), questions: widget.questions); AudioService.playBackground(); }
  @override
  void dispose() { _challengeTimer?.cancel(); AudioService.stopAll(); super.dispose(); }

  void _onPlayerSelected(Player player) {
    AudioService.playWheelSpin();
    setState(() { _selectedPlayer = player; _showPlayerSpinner = false; _showTypeSelector = true; _selectedType = ''; });
  }

  void _selectType(String type) {
    final player = _selectedPlayer;
    if (player != null && type == 'truth' && _lastChosenTypePerPlayer[player.id] == 'truth') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You chose Truth last turn! You must take a Dare this time.'), duration: Duration(seconds: 2)));
      return;
    }
    AudioService.playClick();
    setState(() => _selectedType = type);
  }

  void _startQuestion() {
    final player = _selectedPlayer;
    if (_selectedType.isEmpty || player == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Truth or Dare.'))); return; }
    final matching = _gameState.questions.where((q) => q.type.toLowerCase() == _selectedType).toList();
    final unused = matching.where((q) => !_gameState.usedQuestions.contains(q)).toList();
    final pool = unused.isNotEmpty ? unused : matching;
    if (pool.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions are available for this type.'))); return; }
    final selected = pool[_random.nextInt(pool.length)];
    final processedText = QuestionLoader.processQuestionText(selected.text, player, _gameState.players);
    _challengeTimer?.cancel();
    _lastChosenTypePerPlayer[player.id] = _selectedType;
    setState(() {
      _currentQuestion = selected.copyWith(text: processedText);
      _gameState = _gameState.copyWith(currentType: _selectedType, currentQuestionIndex: _gameState.questions.indexOf(selected), usedQuestions: [..._gameState.usedQuestions, selected], currentPlayerIndex: _gameState.players.indexWhere((item) => item.id == player.id));
      _challengeSecondsLeft = GameRules.dareDurationSeconds; _showTypeSelector = false; _showQuestion = true; _isResolvingChallenge = false;
    });
    AudioService.playCardFlip();
    if (_selectedType == 'dare') _startDareTimer();
  }

  void _startDareTimer() {
    _challengeTimer?.cancel();
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _selectedPlayer == null || _currentQuestion?.type.toLowerCase() != 'dare') { timer.cancel(); return; }
      if (_challengeSecondsLeft <= 1) { timer.cancel(); _applyChallengeResult(successful: false, timedOut: true); return; }
      setState(() => _challengeSecondsLeft--);
    });
  }

  void _applyChallengeResult({required bool successful, bool timedOut = false}) {
    final player = _selectedPlayer;
    if (player == null || _currentQuestion == null || _isResolvingChallenge) return;
    _isResolvingChallenge = true; _challengeTimer?.cancel(); AudioService.playClick();
    final updatedPlayer = player.copyWith(score: GameRules.scoreAfterChallenge(currentScore: player.score, completed: successful), hasCompletedTurn: true);
    final updatedPlayers = [..._gameState.players];
    final playerIndex = updatedPlayers.indexWhere((item) => item.id == player.id);
    if (playerIndex == -1) { _isResolvingChallenge = false; return; }
    updatedPlayers[playerIndex] = updatedPlayer;
    final resultText = successful ? '${player.name} completed the challenge! +${GameRules.pointsForCompletion} points.' : timedOut ? '${player.name} ran out of time. -${GameRules.pointsForFailure} points.' : '${player.name} skipped the challenge. -${GameRules.pointsForFailure} points.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultText), backgroundColor: successful ? AppColors.neonGreen : AppColors.neonRed, duration: const Duration(seconds: 2)));
    setState(() {
      _gameState = _gameState.copyWith(players: updatedPlayers, currentType: ''); _selectedType = ''; _showQuestion = false; _showPlayerSpinner = true; _selectedPlayer = null; _currentQuestion = null; _challengeSecondsLeft = GameRules.dareDurationSeconds; _isResolvingChallenge = false;
    });
    if (updatedPlayers.isNotEmpty && updatedPlayers.every((item) => item.hasCompletedTurn)) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _showLeaderboard(resetRoundOnContinue: true); });
  }

  void _showLeaderboard({bool resetRoundOnContinue = false}) => showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => LeaderboardScreen(players: _gameState.players, onContinue: () {
    Navigator.of(dialogContext).pop();
    if (!resetRoundOnContinue || !mounted) return;
    setState(() { _gameState = _gameState.copyWith(players: _gameState.players.map((player) => player.copyWith(hasCompletedTurn: false)).toList()); });
  }));

  void _endGame() {
    final winner = _gameState.getWinner();
    if (winner == null) return;
    AudioService.playWinner();
    Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => WinnerScreen(winner: winner, players: _gameState.players, onRestart: () => Navigator.pop(context))));
  }

  @override
  Widget build(BuildContext context) {
    final isTruthDisabled = _selectedPlayer != null && _lastChosenTypePerPlayer[_selectedPlayer!.id] == 'truth';
    final stage = _showPlayerSpinner ? 'wheel' : _showTypeSelector ? 'choice' : 'challenge';
    return Scaffold(
      appBar: AppBar(title: Text(_selectedPlayer != null ? "${_selectedPlayer!.name.toUpperCase()}'S TURN" : 'TRUTH OR DARE'), actions: [
        IconButton(tooltip: 'Show leaderboard', icon: const Icon(Icons.leaderboard_rounded, color: AppColors.gold), onPressed: () => _showLeaderboard()),
        IconButton(tooltip: 'End game', icon: const Icon(Icons.flag_rounded, color: AppColors.neonPink), onPressed: _endGame),
      ]),
      body: AppBackground(child: SafeArea(top: false, child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 8), child: Row(children: [Expanded(child: _progressPill('ROUND', _gameState.players.where((p) => p.hasCompletedTurn).length, _gameState.players.length)), const SizedBox(width: 10), _progressPill('SCORE', _gameState.players.fold<int>(0, (sum, p) => sum + p.score), null)])),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 420), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .045), end: Offset.zero).animate(animation), child: child)), child: KeyedSubtree(key: ValueKey(stage), child: _showPlayerSpinner ? _buildSpinnerStage() : _showTypeSelector ? _buildChoiceStage(isTruthDisabled) : _buildQuestionStage()))),
      ]))),
    );
  }

  Widget _progressPill(String label, int value, int? total) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.09))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(width: 8), Text(total == null ? '$value' : '$value/$total', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800))]));

  Widget _buildSpinnerStage() => Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const AppSectionLabel('Every turn starts with a spin'), const SizedBox(height: 8), Text('Who’s up next?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)), const SizedBox(height: 6), const Text('Let fate choose your player.', style: TextStyle(color: AppColors.muted, fontSize: 13)), const SizedBox(height: 18),
    AppGlassPanel(padding: const EdgeInsets.fromLTRB(12, 18, 12, 18), child: PlayerSpinner(players: _gameState.players, onPlayerSelected: _onPlayerSelected)),
  ])));

  Widget _buildChoiceStage(bool isTruthDisabled) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 74, height: 74, decoration: BoxDecoration(shape: BoxShape.circle, color: _getGenderColor(_selectedPlayer?.gender ?? 'Other').withOpacity(.14), border: Border.all(color: _getGenderColor(_selectedPlayer?.gender ?? 'Other').withOpacity(.4))), child: Icon(Icons.person_rounded, color: _getGenderColor(_selectedPlayer?.gender ?? 'Other'), size: 36)),
    const SizedBox(height: 17), const AppSectionLabel('Your moment'), const SizedBox(height: 8), Text("${_selectedPlayer?.name ?? ''}'s turn", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30)), const SizedBox(height: 8), const Text('Choose your path for this round.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
    if (isTruthDisabled) Padding(padding: const EdgeInsets.only(top: 18), child: AppGlassPanel(accent: AppColors.neonPink, padding: const EdgeInsets.all(12), child: const Row(children: [Icon(Icons.lock_outline_rounded, color: AppColors.neonPink, size: 18), SizedBox(width: 9), Expanded(child: Text('Truth is locked this turn—you chose it last time.', style: TextStyle(color: AppColors.white, fontSize: 12)))]))),
    const SizedBox(height: 24), Row(children: [Expanded(child: _choiceCard('TRUTH', 'Be honest. No dodging.', Icons.visibility_rounded, AppColors.neonBlue, isTruthDisabled)), const SizedBox(width: 12), Expanded(child: _choiceCard('DARE', 'Take the challenge.', Icons.bolt_rounded, AppColors.neonPink, false))]),
    const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _selectedType.isNotEmpty ? _startQuestion : null, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('REVEAL MY PROMPT')),
  ])));

  Widget _choiceCard(String title, String subtitle, IconData icon, Color color, bool disabled) {
    final selected = _selectedType == title.toLowerCase();
    return Semantics(button: true, selected: selected, enabled: !disabled, label: title, child: AnimatedOpacity(duration: const Duration(milliseconds: 180), opacity: disabled ? .38 : 1, child: Material(color: Colors.transparent, child: InkWell(onTap: disabled ? null : () => _selectType(title.toLowerCase()), borderRadius: BorderRadius.circular(22), child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12), decoration: BoxDecoration(color: selected ? color.withOpacity(.18) : Colors.white.withOpacity(.045), borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? color : Colors.white.withOpacity(.12), width: selected ? 1.7 : 1), boxShadow: selected ? [BoxShadow(color: color.withOpacity(.14), blurRadius: 24)] : []), child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 12), Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.3))]))))));
  }

  Widget _buildQuestionStage() {
    if (_currentQuestion == null) return const SizedBox.shrink();
    return Column(children: [Padding(padding: const EdgeInsets.only(top: 12), child: AppGlassPanel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_currentQuestion!.type.toLowerCase() == 'truth' ? Icons.visibility_rounded : Icons.bolt_rounded, color: _currentQuestion!.type.toLowerCase() == 'truth' ? AppColors.neonBlue : AppColors.neonPink, size: 16), const SizedBox(width: 8), Text('FOR ${_selectedPlayer?.name.toUpperCase() ?? 'PLAYER'}', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))]))), Expanded(child: _currentQuestion!.type.toLowerCase() == 'truth' ? TruthCard(question: _currentQuestion!, onComplete: () => _applyChallengeResult(successful: true), onFail: () => _applyChallengeResult(successful: false)) : DareCard(question: _currentQuestion!, countdownSeconds: _challengeSecondsLeft, onComplete: () => _applyChallengeResult(successful: true), onFail: () => _applyChallengeResult(successful: false))) ]);
  }

  Color _getGenderColor(String gender) => gender == 'Male' ? AppColors.neonBlue : AppColors.neonPink;
}
