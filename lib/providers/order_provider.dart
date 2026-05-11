import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createOrder(Order order) async {
    try {
      debugPrint('🔵 OrderProvider.createOrder called');
      debugPrint('   Order ID: ${order.id}');
      debugPrint('   Order name: ${order.name}');
      debugPrint('   Items: ${order.items.length}');

      _orders.add(order);

      // ✅ CRITIQUE : Notifier les listeners
      notifyListeners();

      // ✅ Sauvegarder en SharedPreferences
      await _saveOrdersToStorage();

      debugPrint('✅ OrderProvider.createOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 OrderProvider.createOrder FAILED: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrder(Order order) async {
    try {
      debugPrint('🔵 OrderProvider.updateOrder called');
      debugPrint('   Order ID: ${order.id}');

      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx == -1) {
        debugPrint('⚠️ Order not found for update: ${order.id}');
        _error = 'Commande non trouvée';
        notifyListeners();
        return false;
      }

      _orders[idx] = order;

      // ✅ CRITIQUE : Notifier les listeners
      notifyListeners();

      // ✅ Sauvegarder en SharedPreferences
      await _saveOrdersToStorage();

      debugPrint('✅ OrderProvider.updateOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 OrderProvider.updateOrder FAILED: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      debugPrint('🔵 OrderProvider.deleteOrder called: $orderId');

      _orders.removeWhere((o) => o.id == orderId);

      // ✅ Notifier et sauvegarder
      notifyListeners();
      await _saveOrdersToStorage();

      debugPrint('✅ OrderProvider.deleteOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 OrderProvider.deleteOrder FAILED: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> validateOrder(String orderId) async {
    try {
      debugPrint('🔵 OrderProvider.validateOrder called: $orderId');

      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx == -1) {
        debugPrint('⚠️ Order not found for validation: $orderId');
        _error = 'Commande non trouvée';
        notifyListeners();
        return false;
      }

      // ✅ Mettre à jour le statut à validé
      _orders[idx].status = OrderStatus.validated;
      _orders[idx].updatedAt = DateTime.now();

      // ✅ Notifier et sauvegarder
      notifyListeners();
      await _saveOrdersToStorage();

      debugPrint('✅ OrderProvider.validateOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🔴 OrderProvider.validateOrder FAILED: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveOrdersToStorage() async {
    try {
      debugPrint('💾 Saving ${_orders.length} orders to SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();

      // ✅ Convertir la liste en JSON
      final json = jsonEncode(
        _orders.map((order) => order.toMap()).toList(),
      );

      await prefs.setString('orders_list', json);

      debugPrint('✅ Orders saved to storage');
      _error = null;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Storage save failed: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('📂 Loading orders from SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('orders_list');

      if (json == null || json.isEmpty) {
        debugPrint('✅ No orders found (first time)');
        _orders = [];
      } else {
        // ✅ Décoder le JSON et reconstruire les objets
        final List<dynamic> decodedList = jsonDecode(json);
        _orders = decodedList
            .map((item) => Order.fromMap(item as Map<String, dynamic>))
            .toList();

        debugPrint('✅ Orders loaded: ${_orders.length}');
      }

      _error = null;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Load orders failed: $e');
      debugPrint('Stack: $stackTrace');
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
