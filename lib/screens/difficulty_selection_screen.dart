import 'package:flutter/material.dart';
import '../models/difficulty_level.dart';
import '../models/player.dart';
import 'game_screen.dart';
import '../models/question.dart';
import '../utils/question_loader.dart';

class DifficultySelectionScreen extends StatefulWidget {
  final List<Player> players;
  final String selectedLanguage;

  const DifficultySelectionScreen({
    super.key,
    required this.players,
    required this.selectedLanguage,
  });

  @override
  State<DifficultySelectionScreen> createState() =>
      _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState
    extends State<DifficultySelectionScreen> {
  DifficultyLevel _selected = DifficultyLevel.playful;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MODE (${widget.selectedLanguage.toUpperCase()})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Category / Difficulty',
              style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: DifficultyLevel.values
                    .map((d) => _buildCard(d))
                    .toList(),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0080),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'START PLAYING',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(DifficultyLevel d) {
    final selected = _selected == d;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selected = d),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d.color.withOpacity(0.2),
                  border: Border.all(color: d.color, width: 2),
                ),
                child: Icon(
                  d == DifficultyLevel.extreme
                      ? Icons.warning
                      : d == DifficultyLevel.couple
                          ? Icons.favorite
                          : d == DifficultyLevel.wild
                              ? Icons.whatshot
                              : Icons.videogame_asset,
                  color: d.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.displayName,
                      style: TextStyle(
                        color: d.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTagline(d),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Color(0xFFFF0080)),
            ],
          ),
        ),
      ),
    );
  }

  String _getTagline(DifficultyLevel d) {
    switch (d) {
      case DifficultyLevel.vanilla:
        return 'Light & Fun Icebreakers';
      case DifficultyLevel.playful:
        return 'Flirty & Exciting Prompts';
      case DifficultyLevel.wild:
        return 'Daring & Spicy Challenges';
      case DifficultyLevel.extreme:
        return 'Unfiltered & Wild Party Mode';
      case DifficultyLevel.couple:
        return 'Intimate & Deep Partner Questions';
    }
  }

  Future<void> _startGame() async {
    setState(() => _loading = true);
    try {
      List<Question> questions =
          await QuestionLoader.loadQuestions(widget.selectedLanguage);
      
      final filtered = questions.where((q) => q.difficulty == _selected).toList();
      final finalQuestions = filtered.isNotEmpty ? filtered : questions;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            players: widget.players,
            questions: finalQuestions,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF0000)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
