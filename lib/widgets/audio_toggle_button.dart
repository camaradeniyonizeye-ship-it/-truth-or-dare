import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AudioToggleButton extends StatefulWidget {
  const AudioToggleButton({super.key});

  @override
  State<AudioToggleButton> createState() => _AudioToggleButtonState();
}

class _AudioToggleButtonState extends State<AudioToggleButton> {
  bool _enabled = AudioService.isEnabled;

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    final next = !_enabled;
    setState(() => _enabled = next);
    await AudioService.setEnabled(next);

    if (!mounted) return;

    // Play sound effect if SFX is enabled
    if (AudioService.sfxEnabled) {
      AudioService.playClick();
    }

    // Show feedback snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? 'Sound is on' : 'Sound is off'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: next ? AppColors.neonGreen : AppColors.neonRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: _enabled ? 'Turn sound off' : 'Turn sound on',
        onPressed: _toggle,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            _enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            key: ValueKey(_enabled),
            color: _enabled ? AppColors.neonBlue : AppColors.muted,
            size: 26,
          ),
        ),
      );
}
