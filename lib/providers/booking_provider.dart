import 'package:flutter/material.dart';

class BookingProvider with ChangeNotifier {
  // Lista temporária de slots que o user está a selecionar
  final List<DateTime> _selectedSlots = [];
  
  List<DateTime> get selectedSlots => _selectedSlots;

  void addSlot(DateTime slot) {
    if (!_selectedSlots.contains(slot)) {
      _selectedSlots.add(slot);
      notifyListeners(); // Atualiza a barra de "Total: X €" instantaneamente
    }
  }

  void removeSlot(DateTime slot) {
    _selectedSlots.remove(slot);
    notifyListeners();
  }

  void clearCart() {
    _selectedSlots.clear();
    notifyListeners();
  }
  
  // Exemplo de cálculo em tempo real
  double calculateTotal(double pricePerHour) {
    return _selectedSlots.length * pricePerHour;
  }
}