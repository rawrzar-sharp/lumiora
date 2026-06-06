import 'package:flutter/foundation.dart';

class CartManager extends ChangeNotifier {
  // Singleton pattern
  CartManager._internal();
  static final CartManager instance = CartManager._internal();

  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  bool get isEmpty => _items.isEmpty;

  // Menghitung total seluruh quantity item di keranjang
  int get count => _items.fold<int>(0, (s, e) => s + ((e['quantity'] as int?) ?? 0));

  // Menghitung total subtotal harga (termasuk kustomisasi add-ons)
  int get subtotal {
    int total = 0;
    for (var item in _items) {
      int itemCost = (item['basePrice'] as int?) ?? 0;
      
      // Ambil opsi addon dan addon yang sedang dipilih
      final Map<String, int> addonOpts = Map<String, int>.from((item['addonOptions'] as Map?) ?? {});
      final List<String> currentAddons = List<String>.from((item['selectedAddons'] as List?) ?? []);

      for (var addon in currentAddons) {
        itemCost += addonOpts[addon] ?? 0;
      }
      total += itemCost * ((item['quantity'] as int?) ?? 1);
    }
    return total;
  }

  // Menambahkan item baru atau menambah quantity jika item identik sudah ada
  void addItem(Map<String, dynamic> menuItem) {
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

  // Mengubah kuantitas spesifik item berdasarkan index
  void updateQuantity(int index, int qty) {
    if (index >= 0 && index < _items.length) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['quantity'] = qty;
      }
      notifyListeners();
    }
  }

  // Menghapus item pada indeks tertentu
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // --- SOLUSI ERROR COMPILER ---
  // Menambahkan clearCart() agar sesuai dengan panggilan di payment.dart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Tetap mempertahankan clear() agar tidak error jika dipanggil oleh file lama
  void clear() {
    _items.clear();
    notifyListeners();
  }
  // -----------------------------

  // Helper fungsi untuk membandingkan kesamaan addons (List)
  bool _listEq(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is! List || b is! List) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }
}