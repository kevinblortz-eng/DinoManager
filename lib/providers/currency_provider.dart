import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/currency.dart';

class CurrencyProvider extends ChangeNotifier {
  late Currency _defaultCurrency;
  List<Currency> _allCurrencies = [];
  List<Currency> _customCurrencies = [];

  Currency get defaultCurrency => _defaultCurrency;
  List<Currency> get allCurrencies => _allCurrencies;
  List<Currency> get customCurrencies => _customCurrencies;

  CurrencyProvider() {
    _initializeCurrencies();
  }

  void _initializeCurrencies() {
    _allCurrencies = Currency.getDefaults();
    _defaultCurrency = _allCurrencies.first; // TEK par défaut
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Charger la devise par défaut
    final defaultId = prefs.getString('default_currency_id') ?? 'tek';
    _defaultCurrency = _allCurrencies.firstWhere(
      (c) => c.id == defaultId,
      orElse: () => _allCurrencies.first,
    );

    // Charger les devises custom
    final customJson = prefs.getStringList('custom_currencies') ?? [];
    _customCurrencies = customJson
        .map((json) => Currency.fromMap(jsonDecode(json)))
        .toList();

    _allCurrencies = [
      ...Currency.getDefaults(),
      ..._customCurrencies,
    ];

    notifyListeners();
  }

  Future<void> setDefaultCurrency(Currency currency) async {
    _defaultCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_currency_id', currency.id);
    notifyListeners();
  }

  Future<void> addCustomCurrency(String name, String iconPath) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final currency = Currency(
      id: id,
      name: name,
      iconPath: iconPath,
      isCustom: true,
    );

    _customCurrencies.add(currency);
    _allCurrencies.add(currency);

    final prefs = await SharedPreferences.getInstance();
    final customJson = _customCurrencies
        .map((c) => jsonEncode(c.toMap()))
        .toList();
    await prefs.setStringList('custom_currencies', customJson);

    notifyListeners();
  }

  Future<void> removeCurrency(String currencyId) async {
    _customCurrencies.removeWhere((c) => c.id == currencyId);
    _allCurrencies.removeWhere((c) => c.id == currencyId);

    final prefs = await SharedPreferences.getInstance();
    final customJson = _customCurrencies
        .map((c) => jsonEncode(c.toMap()))
        .toList();
    await prefs.setStringList('custom_currencies', customJson);

    notifyListeners();
  }
}
