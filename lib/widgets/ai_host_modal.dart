import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/ai_host_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AiHostModal extends StatefulWidget {
  final Player? currentPlayer;
  final List<Player> allPlayers;

  const AiHostModal({
    super.key,
    required this.currentPlayer,
    required this.allPlayers,
  });

  @override
  State<AiHostModal> createState() => _AiHostModalState();
}

class _AiHostModalState extends State<AiHostModal> {
  final TextEditingController _promptController = TextEditingController();
  String _aiResponse = "I am your AI Host. Ask me for a custom dare, a brutal roast, or judgment.";
  bool _isThinking = false;

  void _askAI(String query) {
    if (query.trim().isEmpty) return;
    AudioService.playClick();
    
    setState(() {
      _isThinking = true;
    });

    // Simulate slight AI thinking latency for realism
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final response = AiHostService.getAIResponse(query, widget.currentPlayer, widget.allPlayers);
      setState(() {
        _aiResponse = response;
        _isThinking = false;
        _promptController.clear();
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.neonPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI HOST COMPANION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
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
          // AI Dialog Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: _isThinking
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonPink),
                      ),
                      SizedBox(width: 10),
                      Text('AI is cooking up a response...', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  )
                : Text(
                    _aiResponse,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Quick Action Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: AppColors.neonPink.withOpacity(0.15),
                labelStyle: const TextStyle(color: AppColors.neonPink, fontSize: 11, fontWeight: FontWeight.w800),
                label: const Text('🔥 Roast Me'),
                onPressed: () => _askAI('roast me'),
              ),
              ActionChip(
                backgroundColor: AppColors.neonBlue.withOpacity(0.15),
                labelStyle: const TextStyle(color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.w800),
                label: const Text('⚡ Custom Dare'),
                onPressed: () => _askAI('give me a custom dare'),
              ),
              ActionChip(
                backgroundColor: AppColors.neonPurple.withOpacity(0.15),
                labelStyle: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w800),
                label: const Text('⚖️ Judge Us'),
                onPressed: () => _askAI('judge us'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Prompt Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ask AI anything...',
                    hintStyle: const TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: _askAI,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () => _askAI(_promptController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
