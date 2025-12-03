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

  Future<User?> register(
    String email,
    String password,
    String name,
    UserType type,
    String? phone, {
    String? licenseNumber, // <- NOVO parâmetro opcional (named)
  }) async {
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

      // --- SE FOR VETERINÁRIO, CRIAR TAMBÉM PERFIL NA BOX DE VETS ---
      if (type == UserType.veterinarian) {
        final trimmedLicense = licenseNumber?.trim() ?? '';

        if (trimmedLicense.isEmpty) {
          throw AuthException(
            'Por favor, introduza a sua cédula profissional.',
          );
        }

        // Só números, mínimo 10
        final digitsOnly = trimmedLicense.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length < 10) {
          throw AuthException(
            'A cédula profissional deve ter pelo menos 10 números.',
          );
        }
        if (!RegExp(r'^\d+$').hasMatch(trimmedLicense)) {
          throw AuthException(
            'A cédula profissional deve conter apenas números.',
          );
        }

        final Box<Map> vetsBox = await LocalStorageService.veterinariansBox();

        final vetData = <String, dynamic>{
          'id': user.id,
          'name': user.name,
          'licenseNumber': trimmedLicense,
          'email': user.email,
          'phone': user.phone ?? '',
          'photo': null,
          'bio': '',
          'species': <String>[],
          'specialties': <String>[],
          'services': <String>[],
          'availability': {
            'emergency': false,
            'homeVisit': false,
            'weekends': false,
            'businessHours': {'start': '09:00', 'end': '18:00'},
          },
          'location': {
            'address': '',
            'city': '',
            'coordinates': {
              'lat': 0.0,
              'lng': 0.0,
            },
          },
          'rating': {
            'average': 0.0,
            'reviews': 0,
          },
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };

        await vetsBox.put(user.id, vetData);
      }
      // --------------------------------------------------------------

      // Guardar o user + password na box de users
      final Map<String, dynamic> dataToStore = {
        'user': user.toMap(),
        'password': password,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      await usersBox.put(normalizedEmail, dataToStore);

      print('User registado com sucesso: ${user.email}');
      return user;
    } on AuthException catch (e) {
      print('AuthException no registo: ${e.message}');
      rethrow;
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
