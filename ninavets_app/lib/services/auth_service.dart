import '../models/user.dart';

class AuthService {
  // Mock login - depois substitui por Firebase Auth
  static Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data - depois vem da base de dados
    if (email == 'vet@ninavets.pt' && password == '123456') {
      return User(
        id: '1',
        email: email,
        name: 'Dr. Silva',
        type: UserType.veterinarian,
        phone: '+351912345678',
        createdAt: DateTime.now(),
      );
    } else if (email == 'student@ninavets.pt' && password == '123456') {
      return User(
        id: '2',
        email: email,
        name: 'Ana Costa',
        type: UserType.student,
        phone: '+351923456789',
        createdAt: DateTime.now(),
      );
    } else if (email == 'client@ninavets.pt' && password == '123456') {
      return User(
        id: '3',
        email: email,
        name: 'Maria Santos',
        type: UserType.client,
        phone: '+351934567890',
        createdAt: DateTime.now(),
      );
    } else {
      return null; // Login falhou
    }
  }

  // Mock register - depois substitui por Firebase Auth
  static Future<User?> register(
    String email, 
    String password, 
    String name, 
    UserType type, 
    String? phone,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Aqui normalmente criarias o user na base de dados
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      type: type,
      phone: phone,
      createdAt: DateTime.now(),
    );
  }
}