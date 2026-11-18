import 'package:material_ui/material_ui.dart'; // ← AJOUT pour Color

class AppVersion {
  final String version;
  final String date;
  final List<ChangelogSection> sections;

  const AppVersion({
    required this.version,
    required this.date,
    required this.sections,
  });
}

class ChangelogSection {
  final ChangelogSectionType type;
  final List<String> items;

  const ChangelogSection({
    required this.type,
    required this.items,
  });
}

enum ChangelogSectionType { nouveaute, amelioration, correction, suppression }

extension ChangelogSectionTypeExt on ChangelogSectionType {
  String get label {
    switch (this) {
      case ChangelogSectionType.nouveaute:
        return 'Nouveautés';
      case ChangelogSectionType.amelioration:
        return 'Améliorations';
      case ChangelogSectionType.correction:
        return 'Corrections';
      case ChangelogSectionType.suppression:
        return 'Suppressions';
    }
  }

  String get emoji {
    switch (this) {
      case ChangelogSectionType.nouveaute:
        return '✨';
      case ChangelogSectionType.amelioration:
        return '⚡';
      case ChangelogSectionType.correction:
        return '🐛';
      case ChangelogSectionType.suppression:
        return '🗑️';
    }
  }

  Color get color {
    switch (this) {
      case ChangelogSectionType.nouveaute:
        return const Color(0xFF4FC3F7);
      case ChangelogSectionType.amelioration:
        return const Color(0xFFFFD700);
      case ChangelogSectionType.correction:
        return const Color(0xFF4CAF50);
      case ChangelogSectionType.suppression:
        return const Color(0xFFEF4444);
    }
  }
}

class ChangelogData {
  static const String currentVersion = '1.2.1';

  static const List<AppVersion> history = [

AppVersion(
  version: '1.2.2',
      date: '12 Mai 2026',
      sections: [
        ChangelogSection(
          type: ChangelogSectionType.nouveaute,
          items: [
            'Couleurs des especes améliorées'
            
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.amelioration,
          items: [
            'Optimisation visuelle des tuiles boutons sur les commandes',
            'Amélioration de l\'affichage des DinoCard Variants',
            ''
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.correction,
          items: [
            ' Correction d\'une anomalie avec les zones morte des dinos',
          ],
        ),
      ],
    ),
    AppVersion(
      version: '1.2.1',
      date: '14 Mai 2026',
      sections: [
        ChangelogSection(
          type: ChangelogSectionType.nouveaute,
          items: [
            'Journal d\'espece plus complet'
            
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.amelioration,
          items: [
            'Optimisation visuelle des tuiles boutons de la bibliothèque',
            'Amélioration de l\'affichage des DinoCard avec un visuel adapté au dino'
            ''
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.correction,
          items: [
            ' Correction de l\'export png avec amélioration générale',
            
          ],
        ),
      ],
    ),
    //
    AppVersion(
      version: '1.2.0',
      date: '10 Mai 2026',
      sections: [
        ChangelogSection(
          type: ChangelogSectionType.nouveaute,
          items: [
            'Commandes : nouveau header sticky avec progression en temps réel',
            'Commandes : jauge circulaire de complétion sur chaque carte',
            'Commandes : résumé automatique paires / mâles / femelles',
            'Commandes : coût par dino ou par paire calculé automatiquement',
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.amelioration,
          items: [
            'Tuiles dino : boutons +/− de validation par genre (♂ / ♀)',
            'Tuiles dino : affichage des stats et couleurs style bibliothèque',
            'Tuiles dino : avatar avec effet de sol ovale sous le dino',
            'Un seul champ Nom remplace les champs Nom + Client',
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.correction,
          items: [
            'Correction du 10% de progression affiché par défaut',
            'Calcul de complétion basé sur mâles et femelles validés séparément',
          ],
        ),
      ],
    ),
    AppVersion(
      version: '1.1.0',
      date: '1 Mai 2026',
      sections: [
        ChangelogSection(
          type: ChangelogSectionType.nouveaute,
          items: [
            'Système de commandes avec suivi de préparation',
            'Sélection de dinos depuis la bibliothèque',
            'Gestion de la monnaie par commande',
          ],
        ),
        ChangelogSection(
          type: ChangelogSectionType.amelioration,
          items: [
            'Bibliothèque : filtres par tags et espèce',
            'Carte dino : affichage des 6 régions de couleur',
          ],
        ),
      ],
    ),
    AppVersion(
      version: '1.0.0',
      date: '15 Avr 2026',
      sections: [
        ChangelogSection(
          type: ChangelogSectionType.nouveaute,
          items: [
            'Lancement de ARK Dino Manager',
            'Bibliothèque de dinos avec stats complètes',
            'Simulateur de breeding',
          ],
        ),
      ],
    ),
  ];

  static AppVersion get current => history.first;
}
