import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player.dart';
import '../services/ai_host_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class AiHostModal extends StatefulWidget {
  final Player? currentPlayer;
  final List<Player> allPlayers;

  const AiHostModal({
    super.key,
    this.currentPlayer,
    required this.allPlayers,
  });

  @override
  State<AiHostModal> createState() => _AiHostModalState();
}

class _AiHostModalState extends State<AiHostModal> {
  final List<Map<String, dynamic>> _conversation = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  Timer? _typingTimer;
  String _currentFullResponse = '';
  int _typingIndex = 0;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text) {
    HapticFeedback.lightImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    setState(() {
      _conversation.add({'sender': 'user', 'text': text, 'time': DateTime.now()});
    });
    final response = AiHostService.getAIResponse(text, widget.currentPlayer, widget.allPlayers);
    _addAIMessage(response);
  }

  void _addAIMessage(String text) {
    setState(() {
      _currentFullResponse = text;
      _typingIndex = 0;
      _isTyping = true;
      _conversation.add({'sender': 'ai', 'text': '', 'time': DateTime.now(), 'isTyping': true});
    });
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (_typingIndex < _currentFullResponse.length) {
        setState(() {
          _conversation.last['text'] = _currentFullResponse.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
      } else {
        timer.cancel();
        setState(() => _isTyping = false);
      }
    });
  }

  void _sendQuickAction(String action) {
    HapticFeedback.lightImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    _messageController.text = action;
    _addUserMessage(action);
  }

  void _resetConversation() {
    HapticFeedback.mediumImpact();
    if (AudioService.sfxEnabled) AudioService.playClick();
    setState(() => _conversation.clear());
    _addAIMessage('Conversation reset! How can I help?');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF140A1F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.neonPink.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.neonPink, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('AI HOST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.muted), tooltip: 'Reset', onPressed: _resetConversation),
              IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.muted), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final msg = _conversation[index];
                final isUser = msg['sender'] == 'user';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.neonPink.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.neonPink, size: 18),
                        ),
                      if (!isUser) const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.neonBlue.withOpacity(0.12) : AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUser ? AppColors.neonBlue.withOpacity(0.3) : AppColors.outline,
                            ),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? AppColors.neonBlue : Colors.white,
                              fontSize: 14.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (isUser)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.neonBlue, size: 18),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('🎲', 'spin the wheel', AppColors.neonPink),
                const SizedBox(width: 8),
                _buildChip('🔥', 'give me a dare', AppColors.neonPink),
                const SizedBox(width: 8),
                _buildChip('💬', 'ask me a truth', AppColors.neonBlue),
                const SizedBox(width: 8),
                _buildChip('👑', 'judge me', AppColors.neonBlue),
                const SizedBox(width: 8),
                _buildChip('💡', 'give me an idea', AppColors.gold),
                const SizedBox(width: 8),
                _buildChip('😈', 'roast me', AppColors.neonRed),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: AppColors.muted),
                    filled: true,
                    fillColor: AppColors.surfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _addUserMessage(text.trim());
                      _messageController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.neonPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    HapticFeedback.lightImpact();
                    if (AudioService.sfxEnabled) AudioService.playClick();
                    _addUserMessage(_messageController.text.trim());
                    _messageController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String emoji, String text, Color color) {
    return ChoiceChip(
      label: Text(emoji),
      selected: false,
      onSelected: (s) => _sendQuickAction(text),
      backgroundColor: color.withOpacity(0.12),
      selectedColor: color.withOpacity(0.24),
      labelStyle: const TextStyle(fontSize: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
