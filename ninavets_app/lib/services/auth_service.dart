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
    await Future.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();

    final demoEntry = _demoUsers[normalizedEmail];
    if (demoEntry != null && demoEntry['password'] == password) {
      return demoEntry['user'] as User;
    }

    final Box<Map<String, dynamic>> usersBox =
        await LocalStorageService.usersBox();
    final Map<String, dynamic>? storedData = usersBox.get(normalizedEmail);

    if (storedData == null) {
      return null;
    }

    if (storedData['password'] != password) {
      return null;
    }

    final userMap = Map<String, dynamic>.from(
      storedData['user'] as Map<dynamic, dynamic>,
    );

    return User.fromMap(userMap);
  }

  static Future<User> register(
    String email,
    String password,
    String name,
    UserType type,
    String? phone,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();

    if (_demoUsers.containsKey(normalizedEmail)) {
      throw AuthException('Este email já está associado a uma conta demo.');
    }

    final Box<Map<String, dynamic>> usersBox =
        await LocalStorageService.usersBox();

    if (usersBox.containsKey(normalizedEmail)) {
      throw AuthException('Este email já está registado.');
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: normalizedEmail,
      name: name,
      type: type,
      phone: phone,
      createdAt: DateTime.now(),
    );

    final Map<String, dynamic> dataToStore = {
      'user': user.toMap(),
      'password': password,
    };

    await usersBox.put(normalizedEmail, dataToStore);

    return user;
  }
}
