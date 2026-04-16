// import 'dart:io'; // ❌ INUTILISÉ - COMMENTÉ
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import '../models/dino.dart'; // ❌ INUTILISÉ - COMMENTÉ

class ArkDinoScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extrait les données d'un dino depuis une capture ARK
  Future<Map<String, dynamic>> scanDinoFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedData = _parseArkText(recognizedText.text);
      final validatedData = _validateAndCleanData(extractedData);
      
      return {
        'success': true,
        'data': validatedData,
        'confidence': _calculateConfidence(validatedData),
        'rawText': recognizedText.text, // Pour debug si nécessaire
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Parse le texte brut extrait spécifiquement pour ARK
  Map<String, dynamic> _parseArkText(String text) {
    final data = <String, dynamic>{};
    final lines = text.split('\n');
    
    // Nettoyage du texte OCR (erreurs courantes)
    text = text.replaceAll(',', '.').replaceAll('O', '0'); // OCR confond souvent O et 0

    // ═══ EXTRACTION DU NIVEAU ═══
    final levelRegex = RegExp(r'(?:Lvl|Level|LVL)\s*(\d+)', caseSensitive: false);
    final levelMatch = levelRegex.firstMatch(text);
    if (levelMatch != null) {
      data['niveau'] = int.tryParse(levelMatch.group(1)!) ?? 1;
    }

    // ═══ EXTRACTION DE L'ESPÈCE (spécialisé ARK) ═══
    final arkSpecies = {
      'REX': 'Rex',
      'GIGA': 'Giganotosaurus', 
      'CARCHA': 'Carcharodontosaurus',
      'ARGENT': 'Argentavis',
      'WYVERN': 'Wyvern',
      'GRIFFIN': 'Griffin',
      'RAPTOR': 'Raptor',
      'SPINO': 'Spinosaurus',
      'OTTER': 'Otter',
      'BABY': '', // On ignore "BABY" pour prendre l'espèce après
    };

    for (final line in lines) {
      final upperLine = line.toUpperCase();
      for (final entry in arkSpecies.entries) {
        if (upperLine.contains(entry.key) && entry.value.isNotEmpty) {
          data['espece'] = entry.value;
          break;
        }
      }
      if (data.containsKey('espece')) break;
    }

    // ═══ EXTRACTION DU NOM ═══
    // Cherche une ligne avec des lettres majuscules (souvent le nom du dino)
    for (final line in lines) {
      if (line.length > 3 && line.contains(RegExp(r'[A-Z]')) && !line.contains('LVL')) {
        // Nettoie le nom (enlève "BABY", niveau, etc.)
        String cleanName = line
            .replaceAll(RegExp(r'BABY\s*'), '')
            .replaceAll(RegExp(r'LVL\s*\d+'), '')
            .replaceAll(RegExp(r'\([^)]*\)'), '')
            .trim();
        if (cleanName.isNotEmpty && cleanName.length < 30) {
          data['nom'] = cleanName;
          break;
        }
      }
    }

    // ═══ EXTRACTION DU SEXE ═══
    if (text.contains('♀') || text.toLowerCase().contains('female') || text.toLowerCase().contains('mat.')) {
      data['sexe'] = 'Femelle';
    } else if (text.contains('♂') || text.toLowerCase().contains('male') || text.toLowerCase().contains('pat.')) {
      data['sexe'] = 'Mâle';
    }

    // ═══ EXTRACTION DES STATS (format ARK) ═══
    
    // Format "valeur / valeur" (HP, Stamina, etc.)
    final slashStatsRegex = RegExp(r'(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)');
    final slashMatches = slashStatsRegex.allMatches(text);
    List<double> statValues = [];
    
    for (final match in slashMatches) {
      final value = double.tryParse(match.group(2) ?? '0') ?? 0; // Prend la valeur max
      if (value > 0) statValues.add(value);
    }

    // Tri par valeur décroissante pour attribution intelligente
    statValues.sort((a, b) => b.compareTo(a));

    // Attribution par heuristique ARK (les plus grandes valeurs sont généralement HP)
    if (statValues.isNotEmpty) {
      data['hp'] = statValues[0].toInt(); // Plus grande = HP
      
      if (statValues.length > 1) {
        // Deuxième plus grande souvent Food ou Stamina
        final secondValue = statValues[1].toInt();
        if (secondValue > 2000) {
          data['nourriture'] = secondValue; // Si > 2000, probablement Food
        } else if (secondValue > 200) {
          data['stamina'] = secondValue; // Sinon Stamina
        }
      }
      
      if (statValues.length > 2) {
        // Troisième valeur souvent Weight ou Oxygen
        final thirdValue = statValues[2].toInt();
        if (thirdValue < 1000) {
          data['poids'] = thirdValue;
        } else {
          data['oxygene'] = thirdValue;
        }
      }
    }

    // Format pourcentage (Dégâts, Vitesse)
    final percentRegex = RegExp(r'(\d+(?:\.\d+)?)\s*%');
    final percentMatches = percentRegex.allMatches(text);
    List<double> percentValues = [];
    
    for (final match in percentMatches) {
      final value = double.tryParse(match.group(1) ?? '100') ?? 100;
      percentValues.add(value);
    }

    percentValues.sort((a, b) => b.compareTo(a));
    
    if (percentValues.isNotEmpty) {
      data['degats'] = percentValues[0]; // Plus gros % = Melee Damage
      
      if (percentValues.length > 1) {
        data['vitesse'] = percentValues[1]; // Deuxième % = Speed
      }
    }

    // ═══ EXTRACTION DES MUTATIONS ═══
    final mutationRegex = RegExp(r'(-?\d+)\s*Mutations', caseSensitive: false);
    final mutationMatch = mutationRegex.firstMatch(text);
    if (mutationMatch != null) {
      final mutations = int.tryParse(mutationMatch.group(1) ?? '0') ?? 0;
      data['mutations'] = mutations.abs(); // Valeur absolue
    }

    return data;
  }

  /// Valide et complète les données avec des valeurs par défaut cohérentes
  Map<String, dynamic> _validateAndCleanData(Map<String, dynamic> raw) {
    return {
      'nom': raw['nom'] ?? 'Dino Importé',
      'espece': raw['espece'] ?? 'Rex',
      'niveau': (raw['niveau'] ?? 1).clamp(1, 500),
      'sexe': raw['sexe'] ?? 'Inconnu',
      'role': 'Solid', // Par défaut, modifiable par l'utilisateur
      
      // Stats avec valeurs minimales réalistes
      'hp': (raw['hp'] ?? 1000).clamp(100, 100000),
      'stamina': (raw['stamina'] ?? 500).clamp(100, 10000),
      'oxygene': (raw['oxygene'] ?? 150).clamp(100, 2000),
      'nourriture': (raw['nourriture'] ?? 2000).clamp(500, 50000),
      'poids': (raw['poids'] ?? 300).clamp(50, 2000),
      'degats': (raw['degats'] ?? 100.0).clamp(100.0, 5000.0),
      'vitesse': (raw['vitesse'] ?? 100.0).clamp(100.0, 300.0),
      
      // Mutations si détectées
      'mutations': raw['mutations'] ?? 0,
      
      // Points à 0 (non extractibles automatiquement)
      'hpPoints': 0,
      'staminaPoints': 0,
      'oxygenePoints': 0,
      'nourriturePoints': 0,
      'poidsPoints': 0,
      'degatsPoints': 0,
      'vitessePoints': 0,
    };
  }

  /// Calcule un score de confiance basé sur la qualité de l'extraction
  int _calculateConfidence(Map<String, dynamic> data) {
    int score = 0;
    
    if (data['nom'] != 'Dino Importé') score += 15;
    if (data['espece'] != 'Rex') score += 20; // Espèce détectée
    if (data['niveau'] > 1) score += 20;
    if (data['sexe'] != 'Inconnu') score += 15;
    if (data['hp'] > 1000) score += 15;
    if (data['degats'] > 100) score += 10;
    if (data['mutations'] > 0) score += 5;
    
    return score.clamp(0, 100);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
