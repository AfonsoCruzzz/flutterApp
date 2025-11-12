import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import 'local_storage_service.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  static final Map<String, Map<String, dynamic>> _demoUsers = {
    'vet@ninavets.pt': {
      'password': '123456',
      'user': User(
        id: '1',
        email: 'vet@ninavets.pt',
        name: 'Dr. Silva',
        type: UserType.veterinarian,
        phone: '+351912345678',
        createdAt: DateTime.now(),
      ),
    },
    'student@ninavets.pt': {
      'password': '123456',
      'user': User(
        id: '2',
        email: 'student@ninavets.pt',
        name: 'Ana Costa',
        type: UserType.student,
        phone: '+351923456789',
        createdAt: DateTime.now(),
      ),
    },
    'client@ninavets.pt': {
      'password': '123456',
      'user': User(
        id: '3',
        email: 'client@ninavets.pt',
        name: 'Maria Santos',
        type: UserType.client,
        phone: '+351934567890',
        createdAt: DateTime.now(),
      ),
    },
  };

  static Future<User?> login(String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final normalizedEmail = email.trim().toLowerCase();

      // Verificar users de demonstração primeiro
      final demoEntry = _demoUsers[normalizedEmail];
      if (demoEntry != null && demoEntry['password'] == password) {
        return demoEntry['user'] as User;
      }

      // Verificar na base de dados local
      final Box<Map> usersBox = await LocalStorageService.usersBox();
      final Map? storedData = usersBox.get(normalizedEmail);

      if (storedData == null) {
        return null;
      }

      final String? storedPassword = storedData['password'] as String?;
      if (storedPassword != password) {
        return null;
      }

      final Map<String, dynamic> userMap =
          Map<String, dynamic>.from(storedData['user'] as Map);

      return User.fromMap(userMap);
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  static Future<User?> register(
    String email,
    String password,
    String name,
    UserType type,
    String? phone,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final normalizedEmail = email.trim().toLowerCase();

      // Validar email
      if (normalizedEmail.isEmpty) {
        throw AuthException('Por favor, insira um email válido.');
      }

      // Validar password
      if (password.length < 6) {
        throw AuthException('A password deve ter pelo menos 6 caracteres.');
      }

      // Verificar se é um email de demonstração
      if (_demoUsers.containsKey(normalizedEmail)) {
        throw AuthException('Este email já está associado a uma conta demo.');
      }

      final Box<Map> usersBox = await LocalStorageService.usersBox();

      // Verificar se email já existe na base de dados
      if (usersBox.containsKey(normalizedEmail)) {
        throw AuthException('Este email já está registado.');
      }

      // Criar novo user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: normalizedEmail,
        name: name.trim(),
        type: type,
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );

      // Preparar dados para guardar
      final Map<String, dynamic> dataToStore = {
        'user': user.toMap(),
        'password': password,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      // Guardar na base de dados
      await usersBox.put(normalizedEmail, dataToStore);

      print('User registado com sucesso: ${user.email}');
      return user;
    } on AuthException catch (e) {
      print('AuthException no registo: ${e.message}');
      rethrow; // Re-lançar a exceção para ser capturada no UI
    } catch (e) {
      print('Erro inesperado no registo: $e');
      throw AuthException('Erro ao criar conta. Tente novamente.');
    }
  }

  // Método auxiliar para verificar se um email já existe
  static Future<bool> emailExists(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      if (_demoUsers.containsKey(normalizedEmail)) {
        return true;
      }

      final Box<Map> usersBox = await LocalStorageService.usersBox();
      return usersBox.containsKey(normalizedEmail);
    } catch (e) {
      print('Erro ao verificar email: $e');
      return false;
    }
  }
}
