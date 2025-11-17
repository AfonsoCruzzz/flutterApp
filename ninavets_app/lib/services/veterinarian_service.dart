import '../models/veterinarian.dart';
import 'local_storage_service.dart';

class VeterinarianService {
  // Helper para converter Map<dynamic, dynamic> para Map<String, dynamic>
  static Map<String, dynamic> _convertMap(Map<dynamic, dynamic> originalMap) {
    return Map<String, dynamic>.from(originalMap);
  }

  // Helper para converter List<dynamic> para List<String>
  static List<String> _convertDynamicListToStringList(dynamic list) {
    if (list == null) return [];
    if (list is List<String>) return list;
    if (list is List<dynamic>) {
      return list.map((item) => item.toString()).toList();
    }
    return [];
  }

  // Buscar todos os veterinários
  static Future<List<Veterinarian>> getAllVeterinarians() async {
    try {
      final vetBox = await LocalStorageService.veterinariansBox();
      final veterinarians = <Veterinarian>[];
      
      for (var key in vetBox.keys) {
        final vetData = vetBox.get(key);
        if (vetData != null) {
          // CONVERTER o map e garantir tipos corretos
          final convertedMap = _convertMap(vetData);
          
          // Converter listas de dynamic para string
          convertedMap['species'] = _convertDynamicListToStringList(convertedMap['species']);
          convertedMap['specialties'] = _convertDynamicListToStringList(convertedMap['specialties']);
          convertedMap['services'] = _convertDynamicListToStringList(convertedMap['services']);
          
          veterinarians.add(Veterinarian.fromMap(convertedMap));
        }
      }
      
      // Ordenar por rating (mais alto primeiro)
      veterinarians.sort((a, b) => b.rating.average.compareTo(a.rating.average));
      
      print('✅ ${veterinarians.length} veterinários carregados');
      return veterinarians;
    } catch (e) {
      print('❌ Erro ao carregar veterinários: $e');
      return [];
    }
  }

  // Buscar veterinário por ID
  static Future<Veterinarian?> getVeterinarianById(String id) async {
    try {
      final vetBox = await LocalStorageService.veterinariansBox();
      final vetData = vetBox.get(id);
      
      if (vetData != null) {
        final convertedMap = _convertMap(vetData);
        
        // Converter listas de dynamic para string
        convertedMap['species'] = _convertDynamicListToStringList(convertedMap['species']);
        convertedMap['specialties'] = _convertDynamicListToStringList(convertedMap['specialties']);
        convertedMap['services'] = _convertDynamicListToStringList(convertedMap['services']);
        
        return Veterinarian.fromMap(convertedMap);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar veterinário por ID: $e');
      return null;
    }
  }

  // Buscar por especialidade
  static Future<List<Veterinarian>> getVeterinariansBySpecialty(String specialty) async {
    final allVets = await getAllVeterinarians();
    return allVets.where((vet) => vet.specialties.contains(specialty)).toList();
  }

  // Buscar por cidade
  static Future<List<Veterinarian>> getVeterinariansByCity(String city) async {
    final allVets = await getAllVeterinarians();
    return allVets.where((vet) => vet.location.city.toLowerCase().contains(city.toLowerCase())).toList();
  }

  // Criar novo veterinário
  static Future<void> createVeterinarian(Veterinarian veterinarian) async {
    try {
      final vetBox = await LocalStorageService.veterinariansBox();
      await vetBox.put(veterinarian.id, veterinarian.toMap());
      print('✅ Veterinário ${veterinarian.name} criado com sucesso');
    } catch (e) {
      print('❌ Erro ao criar veterinário: $e');
      rethrow;
    }
  }

  // Buscar por espécie
  static Future<List<Veterinarian>> getVeterinariansBySpecies(String species) async {
    final allVets = await getAllVeterinarians();
    return allVets.where((vet) => vet.species.contains(species)).toList();
  }
}