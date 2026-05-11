// lib/services/gemini_ocr_service.dart
//
// ─── SERVICE OCR GEMINI ───────────────────────────────────────────────────────
//
// Utilise l'API Gemini Flash (gratuit : 1500 req/jour, 15 req/min)
// pour extraire les stats d'un dino ARK depuis une image.
//
// OBTENIR UNE CLÉ API :
//   1. Allez sur https://aistudio.google.com/
//   2. Connectez-vous avec votre compte Google
//   3. Cliquez sur "Get API key" → "Create API key"
//   4. Copiez la clé (format : AIza...)
//   5. Collez-la dans Dino Manager → Paramètres → OCR / Intelligence Artificielle
//
// MODÈLE UTILISÉ : gemini-2.0-flash (le plus rapide, gratuit)
// QUOTA : 1500 requêtes/jour, 15 req/min (suffisant pour usage normal)
//
// FALLBACK : si la clé est absente ou invalide → OCR local ML Kit
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dino_ocr_service.dart';

class GeminiOcrService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final String apiKey;

  GeminiOcrService(this.apiKey);

  // ─────────────────────────────────────────────────────────────────────────
  // MÉTHODE PRINCIPALE — analyse l'image et retourne un DinoOcrResult
  // ─────────────────────────────────────────────────────────────────────────

  Future<DinoOcrResult> scanImage(File imageFile) async {
    // 1. Encoder l'image en base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Détecter le type MIME
    final mimeType = _detectMimeType(imageFile.path);

    // 2. Construire le prompt structuré
    final prompt = _buildArkPrompt();

    // 3. Appel API Gemini
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
            {'text': prompt},
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.1,        // Très faible : on veut du factuel, pas créatif
        'topK': 1,
        'topP': 0.1,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    };

    final uri = Uri.parse('$_baseUrl?key=$apiKey');

    if (kDebugMode) {
      debugPrint('→ Gemini OCR : envoi image ${imageFile.path}');
    }

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = _parseApiError(response.body);
      throw GeminiOcrException('Erreur API Gemini (${ response.statusCode}): $error');
    }

    // 4. Parser la réponse JSON
    return _parseGeminiResponse(response.body);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROMPT OPTIMISÉ POUR ARK
  // ─────────────────────────────────────────────────────────────────────────

  String _buildArkPrompt() {
    return '''
Tu es un expert en ARK: Survival Ascended. Analyse cette image de stats de dinosaure ARK et extrais les informations.

L'image peut être :
- Une fiche de cryopod (tooltip avec "LVL XXX", stats sans parenthèses)
- Une fiche jumelles TEK (avec format "valeur / max (wild | tame | mut)")
- Un inventaire de créature vivante (même format que jumelles)

Retourne UNIQUEMENT un JSON valide avec cette structure exacte :
{
  "species": "Rex",
  "level": 362,
  "name": "NomDuDino",
  "sex": "♂ ou ♀ ou Inconnu",
  "hp": { "value": 17774.5, "wild": 59, "tame": 0, "mut": 0 },
  "stamina": { "value": 1024.0, "wild": 30, "tame": 0, "mut": 0 },
  "oxygen": { "value": 150.0, "wild": 0, "tame": 0, "mut": 0 },
  "food": { "value": 4000.0, "wild": 25, "tame": 0, "mut": 0 },
  "weight": { "value": 500.0, "wild": 20, "tame": 0, "mut": 0 },
  "melee": { "value": 523.3, "wild": 53, "tame": 0, "mut": 0 },
  "speed": { "value": 100.0, "wild": 0, "tame": 0, "mut": 0 },
  "mutations_male": 0,
  "mutations_female": 0,
  "colors": [1, 0, 2, 0, 3, 2],
  "imprint_percent": 0.0,
  "imprinter": null,
  "source_format": "cryopod"
}

Règles importantes :
- "species" : nom de l'espèce ARK en anglais (Rex, Raptor, Giganotosaurus, etc.)
- "level" : niveau total du dino
- "sex" : utilise ♂ ou ♀ ou "Inconnu" si non visible
- Pour les stats : "value" = valeur max affichée, wild/tame/mut = points (0 si format cryopod)
- "melee" et "speed" sont des pourcentages (ex: 523.3 pour 523.3%)
- "colors" : tableau de 6 entiers (IDs couleur ARK, entre 0-100), 0 si non visible
- "imprint_percent" : 0.0 si pas d'imprint affiché
- "source_format" : "cryopod", "tek_binoculars" ou "inventory"
- Si une stat est absente de l'image, mets null (pas 0)
- Sois précis avec les chiffres, copie exactement ce qui est affiché

Ne retourne QUE le JSON, sans markdown ni texte autour.
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARSING DE LA RÉPONSE GEMINI → DinoOcrResult
  // ─────────────────────────────────────────────────────────────────────────

  DinoOcrResult _parseGeminiResponse(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    // Extraire le texte de la réponse Gemini
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiOcrException('Réponse Gemini vide');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiOcrException('Contenu Gemini vide');
    }

    String rawText = parts[0]['text'] as String? ?? '';

    // Nettoyer le markdown si Gemini l'ajoute quand même
    rawText = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    if (kDebugMode) {
      debugPrint('→ Gemini réponse JSON :\n$rawText');
    }

    // Parser le JSON extrait
    final data = jsonDecode(rawText) as Map<String, dynamic>;

    return _mapToOcrResult(data, rawText);
  }

  DinoOcrResult _mapToOcrResult(Map<String, dynamic> data, String rawText) {
    // Extraire une stat individuelle
    OcrStat? extractStat(String key) {
      final statData = data[key];
      if (statData == null) return null;
      if (statData is Map) {
        final value = (statData['value'] as num?)?.toDouble();
        if (value == null || value == 0) return null;
        return OcrStat(
          currentValue: value,
          maxValue: value,
          wildPoints: (statData['wild'] as num?)?.toInt(),
          tamePoints: (statData['tame'] as num?)?.toInt(),
          mutPoints: (statData['mut'] as num?)?.toInt(),
          isPercent: key == 'melee' || key == 'speed',
        );
      }
      return null;
    }

    // Couleurs : tableau de 6 entiers
    List<int> colors = List.filled(6, 0);
    final rawColors = data['colors'];
    if (rawColors is List) {
      for (int i = 0; i < rawColors.length && i < 6; i++) {
        colors[i] = (rawColors[i] as num?)?.toInt() ?? 0;
      }
    }

    // Format source
    OcrSourceType sourceType;
    switch (data['source_format'] as String? ?? '') {
      case 'cryopod':
        sourceType = OcrSourceType.cryopodTooltip;
        break;
      case 'tek_binoculars':
      case 'inventory':
        sourceType = OcrSourceType.tekBinoculars;
        break;
      default:
        sourceType = OcrSourceType.unknown;
    }

    return DinoOcrResult(
      species: data['species'] as String?,
      level: (data['level'] as num?)?.toInt(),
      name: data['name'] as String?,
      sex: data['sex'] as String?,
      hp: extractStat('hp'),
      stamina: extractStat('stamina'),
      oxygen: extractStat('oxygen'),
      food: extractStat('food'),
      weight: extractStat('weight'),
      melee: extractStat('melee'),
      speed: extractStat('speed'),
      mutationsMale: (data['mutations_male'] as num?)?.toInt(),
      mutationsFemale: (data['mutations_female'] as num?)?.toInt(),
      colorIds: colors,
      imprinter: data['imprinter'] as String?,
      imprintPercent: (data['imprint_percent'] as num?)?.toDouble(),
      rawText: rawText,
      sourceType: sourceType,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITAIRES
  // ─────────────────────────────────────────────────────────────────────────

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // défaut
  }

  String _parseApiError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } catch (_) {
      return body.length > 200 ? body.substring(0, 200) : body;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VÉRIFICATION CLÉ API
  // ─────────────────────────────────────────────────────────────────────────

  /// Teste la validité de la clé API avec une requête minimale
  static Future<bool> validateApiKey(String key) async {
    if (key.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$key');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ─── Exception personnalisée ──────────────────────────────────────────────────
class GeminiOcrException implements Exception {
  final String message;
  GeminiOcrException(this.message);

  @override
  String toString() => 'GeminiOcrException: $message';
}
