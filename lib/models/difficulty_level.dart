import 'package:flutter/material.dart';

enum DifficultyLevel { vanilla, playful, wild, extreme, couple }

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.vanilla:
        return 'Vanilla';
      case DifficultyLevel.playful:
        return 'Playful';
      case DifficultyLevel.wild:
        return 'Wild';
      case DifficultyLevel.extreme:
        return 'Extreme';
      case DifficultyLevel.couple:
        return 'Couples Mode';
    }
  }

  /// Raw database key matching JSON locales ('couples')
  String get apiKey {
    switch (this) {
      case DifficultyLevel.vanilla:
        return 'vanilla';
      case DifficultyLevel.playful:
        return 'playful';
      case DifficultyLevel.wild:
        return 'wild';
      case DifficultyLevel.extreme:
        return 'extreme';
      case DifficultyLevel.couple:
        return 'couples';
    }
  }

  int get levelValue => index + 1;

  Color get color {
    switch (this) {
      case DifficultyLevel.vanilla:
        return const Color(0xFF00FFFF);
      case DifficultyLevel.playful:
        return const Color(0xFF00FF80);
      case DifficultyLevel.wild:
        return const Color(0xFFFF8000);
      case DifficultyLevel.extreme:
        return const Color(0xFFFF0000);
      case DifficultyLevel.couple:
        return const Color(0xFFFF00FF);
    }
  }

  static DifficultyLevel fromString(String v) {
    final lower = v.toLowerCase().replaceAll(' ', '');
    for (var e in DifficultyLevel.values) {
      final nameLower = e.displayName.toLowerCase().replaceAll(' ', '');
      final keyLower = e.apiKey.toLowerCase();
      if (nameLower == lower || keyLower == lower || lower.contains('couple')) {
        return e;
      }
    }
    return DifficultyLevel.playful;
  }
}
