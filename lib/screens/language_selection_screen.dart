import 'package:flutter/material.dart';
import 'player_setup_screen.dart';
import '../services/audio_service.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'name': 'English', 'code': 'English', 'flag': '🇬🇧'},
      {'name': 'Français', 'code': 'French', 'flag': '🇫🇷'},
      {'name': 'Kinyarwanda', 'code': 'Kinyarwanda', 'flag': '🇷🇼'},
      {'name': 'Español', 'code': 'Spanish', 'flag': '🇪🇸'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a0033), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your Language',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return Card(
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      title: Text(lang['name']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.pinkAccent),
                      onTap: () {
                        AudioService.playClick();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerSetupScreen(
                              language: lang['code'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
