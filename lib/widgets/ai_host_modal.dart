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
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _conversationHistory = [];
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;
  String _typingText = "";
  int _typingIndex = 0;
  Timer? _typingTimer;
  String _currentMood = "playful";

  @override
  void initState() {
    super.initState();
    // Initialize with welcome message
    _addToHistory("You", "Hello AI Host!");
    _startTyping(AiHostService.getAIResponse(
      "Hello AI Host!",
      widget.currentPlayer,
      widget.allPlayers,
    ));
    _currentMood = AiHostService.getCurrentMood();
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    
    super.dispose();
  }

  void _addToHistory(String sender, String message) {
    setState(() {
      _conversationHistory.add({'sender': sender, 'message': message});
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _startTyping(String fullText) {
    _typingText = "";
    _typingIndex = 0;
    _typingTimer?.cancel();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typingIndex < fullText.length) {
        setState(() {
          _typingText = fullText.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        _currentMood = AiHostService.getCurrentMood();
      }
    });
  }

  void _askAI(String query) {
    if (query.trim().isEmpty) return;
    AudioService.playClick();

    setState(() {
      _isThinking = true;
      _typingTimer?.cancel();
      _addToHistory("You", query);
    });

    // Process after slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final response = AiHostService.getAIResponse(
        query,
        widget.currentPlayer,
        widget.allPlayers,
      );

      _addToHistory("AI Host", "");
      _startTyping(response);
      setState(() {
        _isThinking = false;
        _promptController.clear();
      });
    });
  }

  String _getMoodIcon() {
    switch (_currentMood) {
      case 'playful': return '🎪';
      case 'sarcastic': return '😏';
      case 'flirty': return '💋';
      case 'serious': return '🎯';
      case 'chaotic': return '🔥';
      default: return '🤖';
    }
  }

  Color _getMoodColor() {
    switch (_currentMood) {
      case 'playful': return AppColors.neonPink;
      case 'sarcastic': return AppColors.neonPurple;
      case 'flirty': return AppColors.neonRed;
      case 'serious': return AppColors.neonBlue;
      case 'chaotic': return Colors.orangeAccent;
      default: return AppColors.neonPink;
    }
  }

  String _getMoodDescription() {
    switch (_currentMood) {
      case 'playful': return 'Fun and mischievous';
      case 'sarcastic': return 'Snarky and judgmental';
      case 'flirty': return 'Seductive and playful';
      case 'serious': return 'Focused and analytical';
      case 'chaotic': return 'Wild and unpredictable';
      default: return 'Neutral';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF140A1F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.neonPink.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with mood indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getMoodColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMoodIcon(),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI HOST COMPANION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${_getMoodIcon()} ${_currentMood.toUpperCase()} - ${_getMoodDescription()}',
                        style: TextStyle(
                          color: _getMoodColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () {
                    _typingTimer?.cancel();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Conversation history
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 350, minHeight: 200),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              reverse: false,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _conversationHistory.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _conversationHistory.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.neonPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neonPink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _conversationHistory[index];
                final isUser = message['sender'] == 'You';
                final isTyping = message['sender'] == 'AI Host' && message['message']!.isEmpty;

                if (isTyping) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.neonPink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.neonPink,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neonPink.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.neonPink.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _typingText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.neonBlue.withOpacity(0.2)
                              : AppColors.neonPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                          color: isUser ? AppColors.neonBlue : AppColors.neonPink,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.neonBlue.withOpacity(0.08)
                                : AppColors.neonPink.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUser
                                  ? AppColors.neonBlue.withOpacity(0.3)
                                  : AppColors.neonPink.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['sender']!,
                                style: TextStyle(
                                  color: isUser
                                      ? AppColors.neonBlue
                                      : AppColors.neonPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['message']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Quick action chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildActionChip('🔥 Roast Me', 'roast me', AppColors.neonPink),
                const SizedBox(width: 6),
                _buildActionChip('⚡ Dare Me', 'give me a dare', AppColors.neonBlue),
                const SizedBox(width: 6),
                _buildActionChip('💬 Secrets', 'what secrets do you know', AppColors.neonPurple),
                const SizedBox(width: 6),
                _buildActionChip('❓ Creator', 'who created you', Colors.orangeAccent),
                const SizedBox(width: 6),
                _buildActionChip('😂 Joke', 'tell me a joke', AppColors.neonGreen),
                const SizedBox(width: 6),
                _buildActionChip('💖 Flirt', 'you are amazing', AppColors.neonRed),
                const SizedBox(width: 6),
                _buildActionChip('👎 Judge', 'judge me', AppColors.neonYellow),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Input field
          Material(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask AI anything...',
                      hintStyle: const TextStyle(color: AppColors.muted),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _askAI,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neonPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _askAI(_promptController.text),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  AiHostService.resetContext();
                  setState(() {
                    _conversationHistory.clear();
                    _conversationHistory.add({
                      'sender': 'You',
                      'message': 'Hello AI Host!'
                    });
                    _startTyping(AiHostService.getAIResponse(
                      "Hello AI Host!",
                      widget.currentPlayer,
                      widget.allPlayers,
                    ));
                    _currentMood = AiHostService.getCurrentMood();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Reset',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final stats = AiHostService.getConversationStats();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF140A1F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: Border.all(color: AppColors.neonPink.withOpacity(0.4)),
                      ),
                      title: const Text(
                        '🤖 AI STATS',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mood: ${stats['mood']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Turns: ${stats['turns']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recent Responses: ${stats['recent_responses_count']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(color: AppColors.neonPink),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_rounded, size: 16),
                label: const Text(
                  'Stats',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String query, Color color) {
    return ActionChip(
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(color: color.withOpacity(0.3), width: 1),
      onPressed: () => _askAI(query),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
