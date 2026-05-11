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
      print('🔵 OrderProvider.createOrder called');
      print('   Order ID: ${order.id}');
      print('   Order name: ${order.name}');
      print('   Items: ${order.items.length}');

      _orders.add(order);

      // ✅ CRITIQUE : Notifier les listeners
      notifyListeners();

      // ✅ Sauvegarder en SharedPreferences
      await _saveOrdersToStorage();

      print('✅ OrderProvider.createOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      print('🔴 OrderProvider.createOrder FAILED: $e');
      print('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrder(Order order) async {
    try {
      print('🔵 OrderProvider.updateOrder called');
      print('   Order ID: ${order.id}');

      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx == -1) {
        print('⚠️ Order not found for update: ${order.id}');
        _error = 'Commande non trouvée';
        notifyListeners();
        return false;
      }

      _orders[idx] = order;

      // ✅ CRITIQUE : Notifier les listeners
      notifyListeners();

      // ✅ Sauvegarder en SharedPreferences
      await _saveOrdersToStorage();

      print('✅ OrderProvider.updateOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      print('🔴 OrderProvider.updateOrder FAILED: $e');
      print('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      print('🔵 OrderProvider.deleteOrder called: $orderId');

      _orders.removeWhere((o) => o.id == orderId);

      // ✅ Notifier et sauvegarder
      notifyListeners();
      await _saveOrdersToStorage();

      print('✅ OrderProvider.deleteOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      print('🔴 OrderProvider.deleteOrder FAILED: $e');
      print('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> validateOrder(String orderId) async {
    try {
      print('🔵 OrderProvider.validateOrder called: $orderId');

      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx == -1) {
        print('⚠️ Order not found for validation: $orderId');
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

      print('✅ OrderProvider.validateOrder SUCCESS');
      return true;
    } catch (e, stackTrace) {
      print('🔴 OrderProvider.validateOrder FAILED: $e');
      print('Stack: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveOrdersToStorage() async {
    try {
      print('💾 Saving ${_orders.length} orders to SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();

      // ✅ Convertir la liste en JSON
      final json = jsonEncode(
        _orders.map((order) => order.toMap()).toList(),
      );

      await prefs.setString('orders_list', json);

      print('✅ Orders saved to storage');
      _error = null;
    } catch (e, stackTrace) {
      print('⚠️ Storage save failed: $e');
      print('Stack: $stackTrace');
      _error = e.toString();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📂 Loading orders from SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('orders_list');

      if (json == null || json.isEmpty) {
        print('✅ No orders found (first time)');
        _orders = [];
      } else {
        // ✅ Décoder le JSON et reconstruire les objets
        final List<dynamic> decodedList = jsonDecode(json);
        _orders = decodedList
            .map((item) => Order.fromMap(item as Map<String, dynamic>))
            .toList();

        print('✅ Orders loaded: ${_orders.length}');
      }

      _error = null;
    } catch (e, stackTrace) {
      print('⚠️ Load orders failed: $e');
      print('Stack: $stackTrace');
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
