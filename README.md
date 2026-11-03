# Truth or Dare

A Flutter party game for adults featuring multilingual prompts, selectable game modes, local player profiles, and a live leaderboard. Please play responsibly and respect each participant's boundaries.

## Features

- Four supported languages: English, French, Kinyarwanda, and Spanish.
- Five categories: Vanilla, Playful, Wild, Extreme, and Couple.
- Add and remove players, with frequently used names saved locally on the device.
- Truth and dare prompts personalized with the current group of players.
- A timed dare round and score updates for completed or skipped challenges.
- A ranked leaderboard and end-of-game winner screen.
- Optional background music and sound effects.

## Requirements

- Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`.
- A supported Flutter target, such as Android, iOS, web, Windows, macOS, or Linux.

## Getting started

```bash
flutter pub get
flutter run
```

Run static analysis and tests before submitting changes:

```bash
flutter analyze
flutter test
```

## How to play

1. Add at least two players. Frequent player names are stored on this device and can be removed with the chip's close button.
2. Choose a category and language, then start the game.
3. Players take turns choosing Truth or Dare. Anyone who chose Truth on their previous turn must choose Dare next.
4. Dares have a 15-second countdown. Mark a challenge as done or skipped; an expired dare is treated as skipped.
5. Completing a challenge awards 10 points. Skipping or timing out removes 5 points, but scores never fall below zero.
6. The leaderboard appears when every player has taken a turn. Use the flag button to end the game early.

## Project layout

- `lib/models/` — player, question, game state, and shared game rules.
- `lib/screens/` — player setup, game, leaderboard, and winner screens.
- `lib/widgets/` — reusable challenge cards and player spinner.
- `lib/data/` and `assets/data/` — prompt data and localized content.
- `assets/` — images, audio, and other bundled resources.

## Notes

- Frequent player names use `shared_preferences`; they remain on the device and are not synced to a server.
- `truth_or_dare_18_web_app.html` is a separate web implementation from the Flutter app.
