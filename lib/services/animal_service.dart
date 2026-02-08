import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';

class AnimalService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // -----------------------------------------------------------------------
  // CRIAR (Create)
  // -----------------------------------------------------------------------
  static Future<void> createAnimal(Animal animal) async {
    try {
      final data = animal.toMap();
      data.remove('id'); 
      
      // Mapeamento para snake_case (para o Supabase)
      final dbData = {
        'owner_id': data['ownerId'],
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'],
        'birth_date': data['birthDate'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(data['birthDate']).toIso8601String() 
            : null,
        'weight': data['weight'],
        'medical_conditions': data['medicalConditions'],
        'medications': data['medications'],
        'allergies': data['allergies'],
        'surgical_history': data['surgicalHistory'],
        'behavior': data['behavior'], 
      };

      await _supabase.from('animals').insert(dbData);
      print('Animal criado no Supabase!');
    } catch (e) {
      print('Erro ao criar animal: $e');
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // LER - LISTA SIMPLES (Future) -> Usado no VeterinariansScreen
  // -----------------------------------------------------------------------
  static Future<List<Animal>> getAnimalsByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('animals')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at');

      // O response vem como List<dynamic>, precisamos converter
      final List<dynamic> data = response;

      return data.map((e) {
        return _mapToAnimal(e);
      }).toList();

    } catch (e) {
      print('Erro ao buscar animais: $e');
      return []; // Retorna lista vazia em caso de erro para não crashar a UI
    }
  }

  // -----------------------------------------------------------------------
  // LER - TEMPO REAL (Stream) -> Podes usar noutros ecrãs de lista
  // -----------------------------------------------------------------------
  static Stream<List<Animal>> getAnimalsStream(String ownerId) {
    return _supabase
        .from('animals')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at')
        .map((List<Map<String, dynamic>> data) {
          return data.map((e) => _mapToAnimal(e)).toList();
        });
  }

  // -----------------------------------------------------------------------
  // HELPER PRIVADO (Para não repetir código de mapeamento)
  // -----------------------------------------------------------------------
  static Animal _mapToAnimal(Map<String, dynamic> e) {
    // Truque para adaptar o JSON snake_case do banco ao camelCase do Model
    final modelMap = Map<String, dynamic>.from(e);
    
    modelMap['ownerId'] = e['owner_id'];
    
    // Tratamento de Arrays (Postgres devolve List<dynamic>, garantimos List<String>)
    modelMap['medicalConditions'] = List<String>.from(e['medical_conditions'] ?? []);
    modelMap['medications'] = List<String>.from(e['medications'] ?? []);
    modelMap['allergies'] = List<String>.from(e['allergies'] ?? []);
    modelMap['surgicalHistory'] = List<String>.from(e['surgical_history'] ?? []);
    
    // Tratamento de Datas (String ISO8601 -> int Milliseconds)
    if (e['birth_date'] != null) {
      modelMap['birthDate'] = DateTime.parse(e['birth_date']).millisecondsSinceEpoch;
    }

    return Animal.fromMap(modelMap);
  }
}