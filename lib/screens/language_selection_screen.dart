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

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<Map<String, String>> languages = const [
    {'name': 'English', 'code': 'English', 'flag': '🇬🇧', 'subtitle': 'Play in English'},
    {'name': 'Français', 'code': 'French', 'flag': '🇫🇷', 'subtitle': 'Jouer en français'},
    {'name': 'Kinyarwanda', 'code': 'Kinyarwanda', 'flag': '🇷🇼', 'subtitle': 'Kina mu Kinyarwanda'},
    {'name': 'Español', 'code': 'Spanish', 'flag': '🇪🇸', 'subtitle': 'Jugar en español'},
  ];

  String? _selectedLanguage;
  bool _isBackConfirmed = false;
  bool _animatedIn = false;

  @override
  void initState() {
    super.initState();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // Animate in after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animatedIn = true);
    });
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
          leading: const SizedBox.shrink(),
          title: AnimatedOpacity(
            opacity: _animatedIn ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: const Text(
              'A NIGHT TO REMEMBER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.muted),
              tooltip: 'About Languages',
              onPressed: _showLanguageInfo,
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
                  
                  // Header Section
                  AnimatedOpacity(
                    opacity: _animatedIn ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: const AppSectionLabel('First things first'),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  AnimatedSlide(
                    offset: _animatedIn ? Offset.zero : const Offset(0, 20),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: Text(
                      'Choose your\nlanguage',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  AnimatedOpacity(
                    opacity: _animatedIn ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: const Text(
                      'Pick the language your group feels most at home in.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Language Cards
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _animatedIn ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: languages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final language = languages[index];
                          final isSelected = _selectedLanguage == language['code'];
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(
                              0,
                              _animatedIn ? 0 : 20,
                              0,
                            ),
                            child: AnimatedScale(
                              scale: isSelected ? 1.0 : 0.99,
                              duration: const Duration(milliseconds: 200),
                              child: AppGlassPanel(
                                padding: EdgeInsets.zero,
                                borderColor: isSelected 
                                    ? AppColors.neonPink.withOpacity(0.5)
                                    : AppColors.outline,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    if (AudioService.sfxEnabled) {
                                      AudioService.playClick();
                                    }
                                    setState(() {
                                      _selectedLanguage = language['code'];
                                    });
                                    // Navigate after a brief delay for visual feedback
                                    Future.delayed(const Duration(milliseconds: 150), () {
                                      Navigator.pushReplacement(
                                        context,
                                        AppRoutes.fadeUp(
                                          PlayerSetupScreen(language: language['code']!),
                                        ),
                                      );
                                    });
                                  },
                                  onHover: (hovering) {
                                    // Optional: Add hover effects for web
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Flag
                                        Container(
                                          width: 54,
                                          height: 54,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceRaised,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected 
                                                  ? AppColors.neonPink.withOpacity(0.3)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Text(
                                            language['flag']!,
                                            style: const TextStyle(fontSize: 27),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 15),
                                        
                                        // Language Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                language['name']!,
                                                style: TextStyle(
                                                  color: isSelected 
                                                      ? AppColors.neonPink
                                                      : AppColors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                language['subtitle']!,
                                                style: TextStyle(
                                                  color: isSelected 
                                                      ? AppColors.neonPink.withOpacity(0.7)
                                                      : AppColors.muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Arrow
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: isSelected 
                                                ? AppColors.neonPink
                                                : AppColors.muted,
                                            key: ValueKey<bool>(isSelected),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Footer
                  AnimatedOpacity(
                    opacity: _animatedIn ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: Center(
                      child: Text(
                        'Ages 18+  •  Keep it fun, keep it consensual',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
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

  void _showLanguageInfo() {
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
                const Icon(Icons.language_rounded, color: AppColors.neonPink),
                const SizedBox(width: 12),
                const Text(
                  'LANGUAGE INFO',
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
            const Text(
              'All questions and dares are translated to maintain the same level of fun and intensity across languages.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: languages.map((lang) {
                return Chip(
                  label: Text(lang['name']!),
                  avatar: Text(lang['flag']!),
                  backgroundColor: AppColors.surfaceRaised,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
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
}
