import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final SupabaseClient _supabase;

  // Se passarmos um cliente (no teste), usa esse. 
  // Se não passarmos nada (na app real), usa o Supabase.instance.client
  AuthService({SupabaseClient? client}) 
      : _supabase = client ?? Supabase.instance.client;

  // ----------------------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------------------
  Future<app_user.User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return null;

      return await _fetchUserProfile(response.user!.id);
    } catch (e) {
      print('Erro no login: $e');
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // REGISTO
  // ----------------------------------------------------------------------
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required app_user.UserType type,
    String? phone,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // 1. Criar Auth User
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (authResponse.user == null) throw Exception("Falha na criação de conta");
      final String userId = authResponse.user!.id;

      // 2. Criar Perfil Base
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': name,
        'phone': phone,
        'role': _userTypeToString(type),
      });

      // 3. Inserir nas tabelas específicas
      if (type == app_user.UserType.veterinarian) {
        if (extraData == null || extraData['license_number'] == null) {
          throw Exception("Cédula profissional obrigatória.");
        }
        await _supabase.from('veterinarians').insert({
          'id': userId,
          'license_number': extraData['license_number'],
          'is_verified': false,
          'specialties': [],
          'species': [],
          'services': [],
        });
      } else if (type == app_user.UserType.student) {
        if (extraData == null || extraData['student_number'] == null) {
          throw Exception("Número de estudante obrigatório.");
        }
        await _supabase.from('students').insert({
          'id': userId,
          'student_number': extraData['student_number'],
          'is_verified': false,
        });
      } else if (type == app_user.UserType.serviceProvider) {
        await _supabase.from('providers').insert({
          'id': userId,
          'housing_type': extraData?['housing_type'],
          'has_fenced_yard': extraData?['has_fenced_yard'] ?? false,
        });
      }
    } catch (e) {
      print('Erro no registo: $e');
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // GET USER DATA (O MÉTODO QUE FALTAVA)
  // ----------------------------------------------------------------------
  Future<app_user.User?> getCurrentUserData() async {
    try {
      final sessionUser = _supabase.auth.currentUser;
      if (sessionUser == null) return null;
      return await _fetchUserProfile(sessionUser.id);
    } catch (e) {
      print('Erro ao obter user data: $e');
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------------------
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ----------------------------------------------------------------------
  // HELPERS PRIVADOS
  // ----------------------------------------------------------------------
  Future<app_user.User> _fetchUserProfile(String userId) async {
    final profileData = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    
    return app_user.User.fromMap(profileData);
  }

  String _userTypeToString(app_user.UserType type) {
    switch (type) {
      case app_user.UserType.veterinarian: return 'veterinarian';
      case app_user.UserType.student: return 'student';
      case app_user.UserType.serviceProvider: return 'provider';
      default: return 'client';
    }
  }
}