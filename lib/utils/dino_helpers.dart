import 'package:flutter/material.dart';
import '../models/dino.dart';

class DinoHelpers {
  
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static int getColorId(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorId0;
      case 1: return dino.colorId1;
      case 2: return dino.colorId2;
      case 3: return dino.colorId3;
      case 4: return dino.colorId4;
      case 5: return dino.colorId5;
      default: return 0;
    }
  }

  static String getColorHex(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorHex0;
      case 1: return dino.colorHex1;
      case 2: return dino.colorHex2;
      case 3: return dino.colorHex3;
      case 4: return dino.colorHex4;
      case 5: return dino.colorHex5;
      default: return '#808080';
    }
  }

  static Color? parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return null;
  }

  static bool isLight(Color color) => color.computeLuminance() > 0.5;

  static Color getCardRarityColor(int niveau) {
    if (niveau >= 362) return const Color(0xFFFFD700);
    if (niveau >= 222) return const Color(0xFFC0C0C0);
    if (niveau >= 150) return const Color(0xFFCD7F32);
    return const Color(0xFF8E8E93);
  }

  static Map<String, int> getRoleDistribution(List<Dino> dinos) {
    final Map<String, int> distribution = {};
    for (var dino in dinos) {
      distribution[dino.role] = (distribution[dino.role] ?? 0) + 1;
    }
    return distribution;
  }

  static Map<String, int> getSexDistribution(List<Dino> dinos) {
    final Map<String, int> distribution = {};
    for (var dino in dinos) {
      distribution[dino.sexe] = (distribution[dino.sexe] ?? 0) + 1;
    }
    return distribution;
  }

  static Dino? getHighestLevelDino(List<Dino> dinos) {
    if (dinos.isEmpty) return null;
    return dinos.reduce((a, b) => a.niveau > b.niveau ? a : b);
  }
}
