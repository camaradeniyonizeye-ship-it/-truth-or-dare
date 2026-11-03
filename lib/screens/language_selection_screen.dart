import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme/app_background.dart';
import '../theme/app_routes.dart';
import '../theme/app_theme.dart';
import 'player_setup_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const languages = [
      {'name': 'English', 'code': 'English', 'flag': '🇬🇧', 'subtitle': 'Play in English'},
      {'name': 'Français', 'code': 'French', 'flag': '🇫🇷', 'subtitle': 'Jouer en français'},
      {'name': 'Kinyarwanda', 'code': 'Kinyarwanda', 'flag': '🇷🇼', 'subtitle': 'Kina mu Kinyarwanda'},
      {'name': 'Español', 'code': 'Spanish', 'flag': '🇪🇸', 'subtitle': 'Jugar en español'},
    ];

    return Scaffold(
      appBar: AppBar(leading: const SizedBox.shrink(), title: const Text('A NIGHT TO REMEMBER')),
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
                Text('Choose your\nlanguage', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 12),
                const Text('Pick the language your group feels most at home in.', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    itemCount: languages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      return AppGlassPanel(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            AudioService.playClick();
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
                                  decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(16)),
                                  child: Text(language['flag']!, style: const TextStyle(fontSize: 27)),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(language['name']!, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text(language['subtitle']!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded, color: AppColors.neonPink),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Center(child: Text('Ages 18+  •  Keep it fun, keep it consensual', style: TextStyle(color: AppColors.muted, fontSize: 11))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
