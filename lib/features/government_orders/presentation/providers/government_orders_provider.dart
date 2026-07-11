import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/government_order_model.dart';
import '../../data/repositories/government_order_repository.dart';

class GovernmentOrdersProvider extends ChangeNotifier {
  final GovernmentOrderRepository _repository;

  GovernmentOrdersProvider({required GovernmentOrderRepository repository})
      : _repository = repository;

  List<GovernmentOrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<GovernmentOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? val) {
    _error = val;
    notifyListeners();
  }

  Future<void> fetchAllOrders() async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _repository.getAllGovernmentOrders();
    } catch (e) {
      _setError('Failed to fetch orders: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addOrder(GovernmentOrderModel order, Uint8List pdfBytes) async {
    _setError(null);
    try {
      await _repository.addGovernmentOrder(model: order, pdfBytes: pdfBytes);
      await fetchAllOrders(); // Refresh list to include generated storage URL
      return true;
    } catch (e) {
      _setError('Failed to add order: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateOrder(GovernmentOrderModel order, Uint8List? pdfBytes) async {
    _setError(null);
    try {
      await _repository.updateGovernmentOrder(model: order, pdfBytes: pdfBytes);
      await fetchAllOrders(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to update order: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteOrder(GovernmentOrderModel order) async {
    _setError(null);
    try {
      await _repository.deleteGovernmentOrder(order);
      _orders.removeWhere((o) => o.id == order.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete order: ${e.toString()}');
      return false;
    }
  }

  Future<Uint8List?> downloadPdf(GovernmentOrderModel order) async {
    try {
      return await _repository.downloadGovernmentOrderPdf(order);
    } catch (e) {
      debugPrint('Failed to download PDF: $e');
      return null;
    }
  }
}
