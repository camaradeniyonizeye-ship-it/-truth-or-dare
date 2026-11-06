import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/difficulty_level.dart';
import '../models/player.dart';
import 'game_screen.dart';
import '../utils/question_loader.dart';
import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_theme.dart';
import '../theme/app_routes.dart';

class DifficultySelectionScreen extends StatefulWidget {
  final List<Player> players;
  final String selectedLanguage;

  const DifficultySelectionScreen({
    super.key,
    required this.players,
    required this.selectedLanguage,
  });

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> {
  DifficultyLevel _selected = DifficultyLevel.playful;
  bool _loading = false;
  bool _isBackConfirmed = false;

  @override
  void initState() {
    super.initState();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
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
          title: Text(
            widget.selectedLanguage.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_isBackConfirmed) {
                Navigator.pop(context);
              } else {
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
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.muted),
              tooltip: 'About Difficulty Levels',
              onPressed: _showDifficultyGuide,
            ),
          ],
        ),
        body: AppBackground(
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  const AppSectionLabel('Set the mood'),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your\nkind of chaos',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick an intensity. You can always keep it comfortable.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Difficulty Cards
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: DifficultyLevel.values.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final level = DifficultyLevel.values[index];
                        return _buildDifficultyCard(level);
                      },
                    ),
                  ),

                  // Start Button
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _startGame,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          _loading ? 'GETTING THINGS READY' : 'START THE PARTY',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Selected indicator
                  if (_selected == DifficultyLevel.extreme)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: AppColors.neonRed,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '18+ Content - No Refunds',
                            style: TextStyle(
                              color: AppColors.neonRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildDifficultyCard(DifficultyLevel level) {
    final selected = _selected == level;
    final icon = _getIcon(level);
    final tagline = _getTagline(level);
    final preview = _getPreview(level);

    return AnimatedScale(
      scale: selected ? 1.0 : 0.99,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: selected
            ? level.color.withOpacity(.14)
            : AppColors.surface.withOpacity(.9),
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () {
            HapticFeedback.mediumImpact();
            if (AudioService.sfxEnabled) {
              AudioService.playClick();
            }
            setState(() => _selected = level);
          },
          onHover: (hovering) {
            // Optional: Add hover effects for web
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selected ? level.color : AppColors.outline,
                width: selected ? 2.0 : 1.0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: level.color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(.18),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: level.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: level.color,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                // Content
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neonRed.withOpacity(.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '18+',
                                style: TextStyle(
                                  color: AppColors.neonRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected ? level.color : AppColors.outline,
                              size: 20,
                              key: ValueKey<bool>(selected),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tagline,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withOpacity(0.9)
                              : AppColors.muted,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (selected)
                        Text(
                          preview,
                          style: TextStyle(
                            color: level.color.withOpacity(0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  IconData _getIcon(DifficultyLevel level) {
    return switch (level) {
      DifficultyLevel.vanilla => Icons.icecream_rounded,
      DifficultyLevel.playful => Icons.sentiment_very_satisfied_rounded,
      DifficultyLevel.wild => Icons.local_fire_department_rounded,
      DifficultyLevel.extreme => Icons.bolt_rounded,
      DifficultyLevel.couple => Icons.favorite_rounded,
    };
  }

  String _getTagline(DifficultyLevel level) {
    return switch (level) {
      DifficultyLevel.vanilla =>
        'Think this is the safe deck? Think again. The first \"who would you fuck?\" lands before round two — and everyone\'s already wet and hard.',
      DifficultyLevel.playful =>
        'Someone here has already pictured you naked. This is where you find out who. Strip on demand, grind laps, and spill secrets.',
      DifficultyLevel.wild =>
        'Everyone\'s got a confession they\'d only make soaked and desperate. This deck drags them out.',
      DifficultyLevel.extreme =>
        'We\'re not going to tell you what\'s on these cards. Some things you have to see for yourself.',
      DifficultyLevel.couple =>
        'There are things you\'ve thought about doing to each other but never dared to say out loud.',
    };
  }

  String _getPreview(DifficultyLevel level) {
    return switch (level) {
      DifficultyLevel.vanilla => 'Mild spice, playful dares, getting comfortable',
      DifficultyLevel.playful => 'Revealing secrets, light teasing, building tension',
      DifficultyLevel.wild => 'Deep confessions, intimate dares, pushing boundaries',
      DifficultyLevel.extreme => 'No limits, explicit content, total abandonment',
      DifficultyLevel.couple => 'Intimate connection, shared fantasies, deep bonding',
    };
  }

  void _showDifficultyGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF140A1F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.neonPink.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.neonPink),
                const SizedBox(width: 12),
                const Text(
                  'DIFFICULTY GUIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...DifficultyLevel.values.map((level) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: level.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIcon(level),
                      color: level.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.displayName,
                          style: TextStyle(
                            color: level.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPreview(level),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'GOT IT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGame() async {
    HapticFeedback.heavyImpact();
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }

    setState(() => _loading = true);

    try {
      // Show loading with mood-based message
      final moodMessage = switch (_selected) {
        DifficultyLevel.vanilla => 'Loading mild chaos...',
        DifficultyLevel.playful => 'Preparing the fun...',
        DifficultyLevel.wild => 'Things are getting wild...',
        DifficultyLevel.extreme => 'Brace yourself...',
        DifficultyLevel.couple => 'Getting intimate...',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(moodMessage),
          backgroundColor: _selected.color.withOpacity(0.8),
          duration: const Duration(seconds: 1),
        ),
      );

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
          content: Text('Error loading questions: $e'),
          backgroundColor: AppColors.neonRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
