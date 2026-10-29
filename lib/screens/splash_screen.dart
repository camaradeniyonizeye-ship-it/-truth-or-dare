import 'package:flutter/material.dart';
import 'player_setup_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerSetupScreen(players: const [], onPlayersAdded: (_) {}),
            ),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_splash.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 2),
                Text(
                  'TRUTH OR DARE',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF0080),
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '18+ PARTY GAME',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(flex: 1),
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0080))),
                SizedBox(height: 20),
                Text('Tap anywhere to start', style: TextStyle(color: Colors.white70)),
                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
