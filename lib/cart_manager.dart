import 'package:flutter/foundation.dart';

class CartManager extends ChangeNotifier {
  CartManager._internal();
  static final CartManager instance = CartManager._internal();

  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  bool get isEmpty => _items.isEmpty;
 int get count => _items.fold<int>(0, (s, e) => s + ((e['quantity'] as int?) ?? 0));

  void addItem(Map<String, dynamic> menuItem) {
    // Cari item identik (id sama + customization sama) → naikkan qty
    final idx = _items.indexWhere((e) =>
        e['id'] == menuItem['id'] &&
        e['selectedSpice'] == menuItem['selectedSpice'] &&
        _listEq(e['selectedAddons'], menuItem['selectedAddons']));
    if (idx >= 0) {
      _items[idx]['quantity'] = (_items[idx]['quantity'] as int) + 1;
    } else {
      _items.add({...menuItem, 'quantity': 1});
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index]['quantity'] = qty;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool _listEq(dynamic a, dynamic b) {
    final la = List.from(a ?? []);
    final lb = List.from(b ?? []);
    if (la.length != lb.length) return false;
    for (int i = 0; i < la.length; i++) if (la[i] != lb[i]) return false;
    return true;
  }
}