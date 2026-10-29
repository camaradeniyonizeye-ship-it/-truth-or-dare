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
        return 'Couple Mode';
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
      if (e.displayName.toLowerCase().replaceAll(' ', '') == lower) {
        return e;
      }
    }
    return DifficultyLevel.playful;
  }
}
