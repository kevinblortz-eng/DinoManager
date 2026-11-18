import 'package:material_ui/material_ui.dart';

class RoleTheme {
  final String role;
  final Color background;  // couleur de fond de la carte
  final Color border;      // couleur de bordure + lueur
  final Color text;        // couleur du texte du badge rôle

  const RoleTheme({
    required this.role,
    required this.background,
    required this.border,
    required this.text,
  });

  // Sérialisation
  Map<String, dynamic> toMap() => {
    'role': role,
    'background': background.toARGB32(),
    'border': border.toARGB32(),
    'text': text.toARGB32(),
  };

  factory RoleTheme.fromMap(Map<String, dynamic> map) => RoleTheme(
    role: map['role'] as String,
    background: Color(map['background'] as int),
    border: Color(map['border'] as int),
    text: Color(map['text'] as int),
  );

  RoleTheme copyWith({Color? background, Color? border, Color? text}) =>
      RoleTheme(
        role: role,
        background: background ?? this.background,
        border: border ?? this.border,
        text: text ?? this.text,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// THÈMES PAR DÉFAUT — un par rôle ARK
// ════════════════════════════════════════════════════════════════════════════
class RoleThemeDefaults {
  static const Map<String, RoleTheme> defaults = {
    'Boss': RoleTheme(
      role: 'Boss',
      background: Color(0xFF2A0A0A),
      border: Color(0xFFFF4444),
      text: Color(0xFFFF4444),
    ),
    'Breed': RoleTheme(
      role: 'Breed',
      background: Color(0xFF0A1A0A),
      border: Color(0xFF4CAF50),
      text: Color(0xFF4CAF50),
    ),
    'Solid': RoleTheme(
      role: 'Solid',
      background: Color(0xFF1A0D00),
      border: Color(0xFFFF6B00),
      text: Color(0xFFFF6B00),
    ),
    'Farm': RoleTheme(
      role: 'Farm',
      background: Color(0xFF1A1A00),
      border: Color(0xFFFFD700),
      text: Color(0xFFFFD700),
    ),
    'Collection': RoleTheme(
      role: 'Collection',
      background: Color(0xFF001A1A),
      border: Color(0xFF00BCD4),
      text: Color(0xFF00BCD4),
    ),
    'Combat': RoleTheme(
      role: 'Combat',
      background: Color(0xFF0D001A),
      border: Color(0xFF9C27B0),
      text: Color(0xFF9C27B0),
    ),
    'Autre': RoleTheme(
      role: 'Autre',
      background: Color(0xFF111827),
      border: Color(0xFF6B7A8D),
      text: Color(0xFF6B7A8D),
    ),
  };

  static RoleTheme forRole(String role) =>
      defaults[role] ??
      const RoleTheme(
        role: 'Autre',
        background: Color(0xFF111827),
        border: Color(0xFF6B7A8D),
        text: Color(0xFF6B7A8D),
      );
}
