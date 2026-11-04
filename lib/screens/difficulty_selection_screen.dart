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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.selectedLanguage.toUpperCase()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: AppBackground(
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionLabel('Set the mood'),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your\nkind of chaos',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick an intensity. You can always keep it comfortable.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: DifficultyLevel.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _buildCard(DifficultyLevel.values[index]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _startGame,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          _loading ? 'GETTING THINGS READY' : 'START THE PARTY',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildCard(DifficultyLevel level) {
    final selected = _selected == level;
    final icon = switch (level) {
      DifficultyLevel.vanilla => Icons.icecream_rounded,
      DifficultyLevel.playful => Icons.sentiment_very_satisfied_rounded,
      DifficultyLevel.wild => Icons.local_fire_department_rounded,
      DifficultyLevel.extreme => Icons.bolt_rounded,
      DifficultyLevel.couple => Icons.favorite_rounded,
    };
    return AnimatedScale(
      scale: selected ? 1.0 : 0.99,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: selected ? level.color.withOpacity(.14) : AppColors.surface.withOpacity(.9),
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => setState(() => _selected = level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selected ? level.color : AppColors.outline,
                width: selected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: level.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            level.displayName,
                            style: TextStyle(
                              color: selected ? level.color : AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (level == DifficultyLevel.extreme)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonPink.withOpacity(.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '18+',
                                style: TextStyle(
                                  color: AppColors.neonPink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Icon(
                            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: selected ? level.color : AppColors.outline,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getTagline(level),
                        style: TextStyle(
                          color: selected ? Colors.white.withOpacity(0.9) : AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTagline(DifficultyLevel level) => switch (level) {
        DifficultyLevel.vanilla =>
          'Think this is the safe deck? Think again. The first "who would you fuck?" lands before round two — and everyone\'s already wet and hard. Every filthy story starts here… and you get to choose how dirty it ends.',
        DifficultyLevel.playful =>
          'Someone here has already pictured you naked. This is where you find out who. Strip on demand, grind laps, and spill secrets that make your friends squeeze their thighs together. The real question is — who\'ll be the first to lose their shirt… and what happens after?',
        DifficultyLevel.wild =>
          'Everyone\'s got a confession they\'d only make soaked and desperate. This deck drags them out. Who do you secretly want to fuck? What do you touch yourself thinking about? The answers will change the way everyone in this room looks at you — forever.',
        DifficultyLevel.extreme =>
          'We\'re not going to tell you what\'s on these cards. Some things you have to see for yourself. All you need to know: nothing is off-limits, nobody leaves clean, and the person you trust most in this room will be the one begging by the end of the night.',
        DifficultyLevel.couple =>
          'There are things you\'ve thought about doing to each other but never dared to say out loud. This deck says them for you — and dares you to do worse. By morning, no hole unexplored, no secret unsaid. The only question is… which one of you breaks first?',
      };

  Future<void> _startGame() async {
    setState(() => _loading = true);
    try {
      final truthQuestions = await QuestionLoader.loadQuestions(
        widget.selectedLanguage,
        category: _selected.displayName,
        type: 'truth',
      );
      final dareQuestions = await QuestionLoader.loadQuestions(
        widget.selectedLanguage,
        category: _selected.displayName,
        type: 'dare',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        AppRoutes.fadeUp(
          GameScreen(
            players: widget.players,
            questions: [...truthQuestions, ...dareQuestions],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
