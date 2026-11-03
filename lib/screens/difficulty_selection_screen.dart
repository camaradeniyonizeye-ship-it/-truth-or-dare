import 'package:flutter/material.dart';
import '../models/difficulty_level.dart';
import '../models/player.dart';
import 'game_screen.dart';
import '../utils/question_loader.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
import '../theme/app_routes.dart';

class DifficultySelectionScreen extends StatefulWidget {
  final List<Player> players;
  final String selectedLanguage;
  const DifficultySelectionScreen({super.key, required this.players, required this.selectedLanguage});
  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  DifficultyLevel _selected = DifficultyLevel.playful;
  bool _loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.selectedLanguage.toUpperCase()), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))), body: AppBackground(child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const AppSectionLabel('Set the mood'), const SizedBox(height: 10), Text('Choose your\nkind of chaos', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30)), const SizedBox(height: 8), const Text('Pick an intensity. You can always keep it comfortable.', style: TextStyle(color: AppColors.muted, fontSize: 13)), const SizedBox(height: 18),
    Expanded(child: ListView.separated(itemCount: DifficultyLevel.values.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) => _buildCard(DifficultyLevel.values[index]))),
    const SizedBox(height: 14), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _loading ? null : _startGame, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow_rounded), label: Text(_loading ? 'GETTING THINGS READY' : 'START THE PARTY'))),
  ])))));

  Widget _buildCard(DifficultyLevel level) {
    final selected = _selected == level;
    final icon = switch (level) { DifficultyLevel.vanilla => Icons.icecream_rounded, DifficultyLevel.playful => Icons.sentiment_very_satisfied_rounded, DifficultyLevel.wild => Icons.local_fire_department_rounded, DifficultyLevel.extreme => Icons.bolt_rounded, DifficultyLevel.couple => Icons.favorite_rounded };
    return AnimatedScale(scale: selected ? 1 : .985, duration: const Duration(milliseconds: 180), child: Material(color: selected ? level.color.withOpacity(.13) : AppColors.surface.withOpacity(.9), borderRadius: BorderRadius.circular(19), child: InkWell(borderRadius: BorderRadius.circular(19), onTap: () => setState(() => _selected = level), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), border: Border.all(color: selected ? level.color : AppColors.outline, width: selected ? 1.5 : 1)), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: level.color.withOpacity(.15), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: level.color)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(level.displayName, style: TextStyle(color: selected ? level.color : AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(_getTagline(level), style: const TextStyle(color: AppColors.muted, fontSize: 12))])), if (level == DifficultyLevel.extreme) Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: AppColors.neonPink.withOpacity(.18), borderRadius: BorderRadius.circular(8)), child: const Text('18+', style: TextStyle(color: AppColors.neonPink, fontSize: 10, fontWeight: FontWeight.w900))), Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? level.color : AppColors.outline)])))));
  }

  String _getTagline(DifficultyLevel level) => switch (level) { DifficultyLevel.vanilla => 'Light & fun icebreakers', DifficultyLevel.playful => 'Flirty & exciting prompts', DifficultyLevel.wild => 'Daring & spicy challenges', DifficultyLevel.extreme => 'Unfiltered party mode (18+)', DifficultyLevel.couple => 'Intimate partner questions' };

  Future<void> _startGame() async {
    setState(() => _loading = true);
    try {
      final truthQuestions = await QuestionLoader.loadQuestions(widget.selectedLanguage, category: _selected.displayName, type: 'truth');
      final dareQuestions = await QuestionLoader.loadQuestions(widget.selectedLanguage, category: _selected.displayName, type: 'dare');
      if (!mounted) return;
      Navigator.push(context, AppRoutes.fadeUp(GameScreen(players: widget.players, questions: [...truthQuestions, ...dareQuestions])));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.neonRed));
    } finally { if (mounted) setState(() => _loading = false); }
  }
}
