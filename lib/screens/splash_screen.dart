import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../data/game_data.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isReady = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AudioService.playBackground();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await GameData.init();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isReady = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isReady = false;
        _error = error.toString();
      });
    }
  }

  void _goNext() {
    if (!_isReady) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goNext,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_splash.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.pinkAccent)
                    else
                      Icon(
                        _isReady ? Icons.check_circle : Icons.error_outline,
                        color: _isReady ? Colors.pinkAccent : Colors.redAccent,
                        size: 56,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _isLoading
                          ? 'Loading questions and game data...'
                          : _isReady
                              ? 'Tap anywhere to start'
                              : 'Could not load game data. Tap Retry.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    if (!_isLoading && !_isReady) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
