import 'package:hive_flutter/hive_flutter.dart';
import '../models/dino.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _boxName = 'dinos_box';
  static const String _ordersBoxName = 'orders_box';
  static const String _counterKey = '__id_counter__';

  Box<Map>? _box;
  Box<Map>? _ordersBox;

  Future<Box<Map>> get box async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Future<Box<Map>> get ordersBox async {
    _ordersBox ??= await Hive.openBox<Map>(_ordersBoxName);
    return _ordersBox!;
  }

  // ─────────────────────────────────────────────────────────────
  // ID auto-incrémenté pour Dinos
  // ─────────────────────────────────────────────────────────────
  Future<int> _nextId() async {
    final b = await box;
    final current = b.get(
      _counterKey,
      defaultValue: <String, dynamic>{'v': 0},
    );

    final currentMap = Map<String, dynamic>.from(current ?? {'v': 0});
    final id = (currentMap['v'] as int? ?? 0) + 1;

    await b.put(_counterKey, <String, dynamic>{'v': id});
    return id;
  }

  Future<void> _setCounterToAtLeast(int value) async {
    final b = await box;
    final current = b.get(
      _counterKey,
      defaultValue: <String, dynamic>{'v': 0},
    );

    final currentMap = Map<String, dynamic>.from(current ?? {'v': 0});
    final currentValue = currentMap['v'] as int? ?? 0;

    if (value > currentValue) {
      await b.put(_counterKey, <String, dynamic>{'v': value});
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Initialisation + samples
  // ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    final b = await box;

    final realEntries = b.values.where((v) {
      final m = Map<String, dynamic>.from(v);
      return m.containsKey('nom');
    }).toList();

    if (realEntries.isEmpty) {
      await _insertSampleDinos();
    }
  }

  Future<void> _insertSampleDinos() async {
    final samples = [
      Dino(
        nom: 'Alpha Prime',
        espece: 'Rex',
        sexe: 'Mâle',
        role: 'Boss',
        niveau: 224,
        hp: 15420,
        stamina: 1850,
        oxygene: 150,
        nourriture: 12000,
        poids: 450,
        degats: 423.5,
        vitesse: 100.0,
        hpPoints: 44,
        staminaPoints: 20,
        oxygenePoints: 0,
        nourriturePoints: 10,
        poidsPoints: 8,
        degatsPoints: 42,
        vitessePoints: 0,
        mutations: '0/20',
        mutationsMaternal: 0,
        mutationsPaternal: 0,
        couleur0: '73:#EF3100',
        couleur1: '74:#FF5834',
        couleur2: '75:#FF7F00',
        couleur3: '79:#171717',
        couleur4: '73:#EF3100',
        couleur5: '75:#FF7F00',
        tagVersion: 'Deadpool',
        notes: 'Rex boss PvE parfait. 44 pts HP, 42 pts dégâts.',
        dateAjout: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Dino(
        nom: 'Shadow Blade',
        espece: 'Raptor',
        sexe: 'Femelle',
        role: 'Combat',
        niveau: 187,
        hp: 3850,
        stamina: 2100,
        oxygene: 150,
        nourriture: 6500,
        poids: 320,
        degats: 298.0,
        vitesse: 178.5,
        hpPoints: 22,
        staminaPoints: 30,
        oxygenePoints: 0,
        nourriturePoints: 5,
        poidsPoints: 10,
        degatsPoints: 25,
        vitessePoints: 15,
        mutations: '4/20',
        mutationsMaternal: 2,
        mutationsPaternal: 2,
        couleur0: '79:#171717',
        couleur1: '54:#4568D4',
        couleur2: '56:#515151',
        couleur3: '79:#171717',
        couleur4: '54:#4568D4',
        couleur5: '29:#394263',
        tagVersion: 'CC',
        notes: 'Raptor CC bleu nuit. 4 mutations dégâts.',
        dateAjout: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Dino(
        nom: 'Frost Wing',
        espece: 'Fire Wyvern',
        sexe: 'Femelle',
        role: 'Combat',
        niveau: 256,
        hp: 18900,
        stamina: 3200,
        oxygene: 150,
        nourriture: 8000,
        poids: 680,
        degats: 512.0,
        vitesse: 100.0,
        hpPoints: 55,
        staminaPoints: 35,
        oxygenePoints: 0,
        nourriturePoints: 10,
        poidsPoints: 15,
        degatsPoints: 48,
        vitessePoints: 0,
        mutations: '2/20',
        mutationsMaternal: 1,
        mutationsPaternal: 1,
        couleur0: '18:#FFFFFF',
        couleur1: '5:#00FFFF',
        couleur2: '96:#ACEAFF',
        couleur3: '18:#FFFFFF',
        couleur4: '5:#00FFFF',
        couleur5: '5:#00FFFF',
        tagVersion: 'Solid',
        notes: 'Wyvern glace. 2 mutations HP.',
        dateAjout: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Dino(
        nom: 'Terra Stomper',
        espece: 'Ankylosaurus',
        sexe: 'Mâle',
        role: 'Farm',
        niveau: 145,
        hp: 9800,
        stamina: 980,
        oxygene: 150,
        nourriture: 7500,
        poids: 1200,
        degats: 185.0,
        vitesse: 100.0,
        hpPoints: 30,
        staminaPoints: 8,
        oxygenePoints: 0,
        nourriturePoints: 8,
        poidsPoints: 40,
        degatsPoints: 12,
        vitessePoints: 0,
        mutations: '0/0',
        mutationsMaternal: 0,
        mutationsPaternal: 0,
        couleur0: '22:#88532F',
        couleur1: '33:#948575',
        couleur2: '15:#593A2A',
        couleur3: '34:#594E41',
        couleur4: '4:#FFFF00',
        couleur5: '33:#948575',
        tagVersion: 'Solid',
        notes: 'Anky farm minerai. 40 pts poids.',
        dateAjout: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    for (final dino in samples) {
      await insertDino(dino);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD DINOS
  // ─────────────────────────────────────────────────────────────
  Future<int> insertDino(Dino dino) async {
    final b = await box;
    final id = await _nextId();
    final map = Map<String, dynamic>.from(dino.toMap());
    map['id'] = id;
    await b.put('dino_$id', map);
    return id;
  }

  Future<List<Dino>> getAllDinos() async {
    final b = await box;
    final results = <Dino>[];

    for (final key in b.keys) {
      if (key == _counterKey) continue;

      final raw = b.get(key);
      if (raw == null) continue;

      final map = Map<String, dynamic>.from(raw);
      if (!map.containsKey('nom')) continue;

      try {
        results.add(Dino.fromMap(map));
      } catch (_) {}
    }

    results.sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
    return results;
  }

  Future<Dino?> getDinoById(int id) async {
    final b = await box;
    final raw = b.get('dino_$id');
    if (raw == null) return null;
    return Dino.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<int> updateDino(Dino dino) async {
    if (dino.id == null) return 0;

    final b = await box;
    await b.put('dino_${dino.id}', Map<String, dynamic>.from(dino.toMap()));
    return 1;
  }

  Future<int> deleteDino(int id) async {
    final b = await box;
    await b.delete('dino_$id');
    return 1;
  }

  Future<void> replaceAllDinos(List<Dino> dinos) async {
    final b = await box;

    final keysToDelete = b.keys
        .where((key) => key != _counterKey)
        .map((key) => key.toString())
        .toList();

    if (keysToDelete.isNotEmpty) {
      await b.deleteAll(keysToDelete);
    }

    int maxId = 0;

    for (final dino in dinos) {
      int id;

      if (dino.id != null && dino.id! > 0) {
        id = dino.id!;
      } else {
        id = maxId + 1;
      }

      if (id > maxId) {
        maxId = id;
      }

      final map = Map<String, dynamic>.from(dino.toMap());
      map['id'] = id;

      await b.put('dino_$id', map);
    }

    await _setCounterToAtLeast(maxId);
  }

  Future<List<Dino>> searchDinos({
    String? query,
    String? espece,
    String? sexe,
    String? role,
    String? tagVersion,
  }) async {
    final all = await getAllDinos();

    return all.where((dino) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!dino.nom.toLowerCase().contains(q) &&
            !dino.espece.toLowerCase().contains(q)) {
          return false;
        }
      }

      if (espece != null && espece.isNotEmpty && dino.espece != espece) {
        return false;
      }

      if (sexe != null && sexe.isNotEmpty && dino.sexe != sexe) {
        return false;
      }

      if (role != null && role.isNotEmpty && dino.role != role) {
        return false;
      }

      if (tagVersion != null &&
          tagVersion.isNotEmpty &&
          dino.tagVersion != tagVersion) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<int> getDinoCount() async {
    final all = await getAllDinos();
    return all.length;
  }

  Future<List<String>> getDistinctEspeces() async {
    final all = await getAllDinos();
    return all.map((d) => d.espece).toSet().toList()..sort();
  }

  Future<void> clearAll() async {
    final b = await box;
    final keysToDelete = b.keys
        .where((key) => key != _counterKey)
        .map((key) => key.toString())
        .toList();

    if (keysToDelete.isNotEmpty) {
      await b.deleteAll(keysToDelete);
    }

    await b.put(_counterKey, <String, dynamic>{'v': 0});
  }

  // ════════════════════════════════════════════
  // CRUD COMMANDES (Orders) avec HIVE
  // ════════════════════════════════════════════

  Future<int> insertOrder(Order order) async {
    final b = await ordersBox;
    await b.put('order_${order.id}', Map<String, dynamic>.from(order.toMap()));
    return 1;
  }

  Future<void> updateOrder(Order order) async {
    final b = await ordersBox;
    order.updatedAt = DateTime.now();
    await b.put('order_${order.id}', Map<String, dynamic>.from(order.toMap()));
  }

  Future<void> deleteOrder(String id) async {
    final b = await ordersBox;
    await b.delete('order_$id');
  }

  Future<Order?> getOrder(String id) async {
    final b = await ordersBox;
    final raw = b.get('order_$id');
    if (raw == null) return null;
    return Order.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<List<Order>> getAllOrders() async {
    final b = await ordersBox;
    final results = <Order>[];

    for (final key in b.keys) {
      final raw = b.get(key);
      if (raw == null) continue;

      final map = Map<String, dynamic>.from(raw);
      if (!map.containsKey('id')) continue;

      try {
        results.add(Order.fromMap(map));
      } catch (e) {
        debugPrint('Erreur parsing Order: $e');
      }
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Future<void> clearAllOrders() async {
    final b = await ordersBox;
    await b.deleteAll(b.keys);
  }

  Future<void> close() async {
    await _box?.close();
    await _ordersBox?.close();
    _box = null;
    _ordersBox = null;
  }
}
