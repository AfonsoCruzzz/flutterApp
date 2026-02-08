import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/veterinarian.dart';

class VeterinarianService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Buscar todos os veterinários (Só os verificados)
  static Future<List<Veterinarian>> getAllVeterinarians() async {
    try {
      // Fazemos select na tabela veterinarians e buscamos o nome na tabela profiles
      final response = await _supabase
          .from('veterinarians')
          .select('*, profiles(full_name, email, phone)')
          .eq('is_verified', true)
          .eq('is_active', true); // Só traz os ativos


      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((e) {
        final profile = e['profiles'] is Map ? e['profiles'] : {};
        
        // Criamos uma cópia do mapa original para injetar os dados do profile
        final Map<String, dynamic> fullMap = Map<String, dynamic>.from(e);
        
        // O Veterinarian.fromMap já sabe lidar com 'full_name', 'email' e 'phone'
        // se estiverem no nível superior ou dentro de 'profiles'
        fullMap['full_name'] = profile['full_name'];
        fullMap['email'] = profile['email'];
        fullMap['phone'] = profile['phone'];

        return Veterinarian.fromMap(fullMap);
      }).toList();

    } catch (e) {
      print('Erro ao buscar veterinários: $e');
      return [];
    }
  }

  // Buscar por Cidade (Usando filtro do Supabase)
  static Future<List<Veterinarian>> getVeterinariansByCity(String city) async {
    // Como ainda não implementámos a lógica complexa de UI, 
    // filtramos no cliente para ser mais rápido adaptar o teu código antigo
    final allVets = await getAllVeterinarians();
    return allVets.where((vet) => 
      vet.location.city.toLowerCase().contains(city.toLowerCase())
    ).toList();
  }
}