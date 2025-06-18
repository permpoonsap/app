import 'package:flutter/material.dart';
import '../model/medicine_item.dart';

class MedicineProvider with ChangeNotifier {
  final List<MedicineItem> _items = [];

  List<MedicineItem> get items => _items;

  void addMedicine(MedicineItem item) {
    _items.add(item);
    notifyListeners();
  }
  void toggleTaken(MedicineItem item) {
  final index = _items.indexOf(item);
  if (index != -1) {
    _items[index].isTaken = !_items[index].isTaken;
    notifyListeners();
  }
}

void removeMedicine(MedicineItem item) {
  _items.remove(item);
  notifyListeners();
}
}
