import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_routes.dart';
import '../theme/app_theme.dart';
import 'player_setup_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with SingleTickerProviderStateMixin {
  DateTime? _lastBackPress;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastBackPress = now;
    HapticFeedback.lightImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap back again to exit'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    return false;
  }

  void _showInfoModal() {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140A1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonPink.withOpacity(0.4), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.neonPink),
            SizedBox(width: 10),
            Text('ABOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A Night to Remember', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('The ultimate party game for adults. Spin, choose truth or dare, and let the chaos unfold.', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            SizedBox(height: 12),
            Text('Ages 18+', style: TextStyle(color: AppColors.neonRed, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 4),
            Text('Play responsibly and with consent.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const languages = [
      {'name': 'English', 'code': 'English', 'flag': '🇬🇧', 'subtitle': 'Play in English'},
      {'name': 'Français', 'code': 'French', 'flag': '🇫🇷', 'subtitle': 'Jouer en français'},
      {'name': 'Kinyarwanda', 'code': 'Kinyarwanda', 'flag': '🇷🇼', 'subtitle': 'Kina mu Kinyarwanda'},
      {'name': 'Español', 'code': 'Spanish', 'flag': '🇪🇸', 'subtitle': 'Jugar en español'},
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const SizedBox.shrink(),
          title: ScaleTransition(
            scale: _scaleAnimation,
            child: const Text(
              'A NIGHT TO REMEMBER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.muted),
              tooltip: 'About',
              onPressed: _showInfoModal,
            ),
          ],
        ),
        body: AppBackground(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const AppSectionLabel('First things first'),
                  const SizedBox(height: 12),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'Choose your\\nlanguage',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pick the language your group feels most at home in.',
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: languages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        return AppGlassPanel(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (AudioService.sfxEnabled) AudioService.playClick();
                              Navigator.pushReplacement(
                                context,
                                AppRoutes.fadeUp(PlayerSetupScreen(language: language['code'])),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceRaised,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      language['flag']!,
                                      style: const TextStyle(fontSize: 27),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          language['name']!,
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          language['subtitle']!,
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.neonPink,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Ages 18+  •  Keep it fun, keep it consensual',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
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
}
