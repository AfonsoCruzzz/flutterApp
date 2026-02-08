import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  final AuthService _authService = AuthService(); // Instância do serviço

  User? get currentUser => _currentUser;

  // Define o user manualmente (usado no Login/Registo)
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // --- A FUNÇÃO NOVA QUE FALTA ---
  // Esta função força a atualização dos dados da BD para a App
  Future<void> refreshUser() async {
    try {
      // Vai buscar os dados fresquinhos ao Supabase (incluindo address, city, etc.)
      final updatedUser = await _authService.getCurrentUserData();
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners(); // Avisa todos os ecrãs (Profile, Home) para se redesenharem
      }
    } catch (e) {
      print("Erro ao atualizar user provider: $e");
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}