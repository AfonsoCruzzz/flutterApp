import '../models/animal.dart';
import 'local_storage_service.dart';

class AnimalService {
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

  // Criar animal
  static Future<void> createAnimal(Animal animal) async {
    try {
      final animalBox = await LocalStorageService.animalsBox();
      await animalBox.put(animal.id, animal.toMap());
      print('✅ Animal ${animal.name} criado com sucesso');
    } catch (e) {
      print('❌ Erro ao criar animal: $e');
      rethrow;
    }
  }

  // Buscar animais por dono
  static Future<List<Animal>> getAnimalsByOwner(String ownerId) async {
    try {
      final animalBox = await LocalStorageService.animalsBox();
      final animals = <Animal>[];
      
      for (var key in animalBox.keys) {
        final animalData = animalBox.get(key);
        if (animalData != null) {
          final convertedMap = _convertMap(animalData);
          
          // Converter listas de dynamic para string
          convertedMap['medicalConditions'] = _convertDynamicListToStringList(convertedMap['medicalConditions']);
          convertedMap['medications'] = _convertDynamicListToStringList(convertedMap['medications']);
          convertedMap['allergies'] = _convertDynamicListToStringList(convertedMap['allergies']);
          convertedMap['surgicalHistory'] = _convertDynamicListToStringList(convertedMap['surgicalHistory']);
          
          final animal = Animal.fromMap(convertedMap);
          if (animal.ownerId == ownerId) {
            animals.add(animal);
          }
        }
      }
      
      // Ordenar por data de criação (mais recente primeiro)
      animals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ ${animals.length} animais carregados para o dono $ownerId');
      return animals;
    } catch (e) {
      print('❌ Erro ao carregar animais: $e');
      return [];
    }
  }

  // Buscar animal por ID
  static Future<Animal?> getAnimalById(String id) async {
    try {
      final animalBox = await LocalStorageService.animalsBox();
      final animalData = animalBox.get(id);
      
      if (animalData != null) {
        final convertedMap = _convertMap(animalData);
        
        // Converter listas de dynamic para string
        convertedMap['medicalConditions'] = _convertDynamicListToStringList(convertedMap['medicalConditions']);
        convertedMap['medications'] = _convertDynamicListToStringList(convertedMap['medications']);
        convertedMap['allergies'] = _convertDynamicListToStringList(convertedMap['allergies']);
        convertedMap['surgicalHistory'] = _convertDynamicListToStringList(convertedMap['surgicalHistory']);
        
        return Animal.fromMap(convertedMap);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar animal por ID: $e');
      return null;
    }
  }

  // Atualizar animal
  static Future<void> updateAnimal(Animal animal) async {
    try {
      final animalBox = await LocalStorageService.animalsBox();
      await animalBox.put(animal.id, animal.toMap());
      print('✅ Animal ${animal.name} atualizado com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar animal: $e');
      rethrow;
    }
  }

  // Eliminar animal
  static Future<void> deleteAnimal(String id) async {
    try {
      final animalBox = await LocalStorageService.animalsBox();
      await animalBox.delete(id);
      print('✅ Animal $id eliminado com sucesso');
    } catch (e) {
      print('❌ Erro ao eliminar animal: $e');
      rethrow;
    }
  }
}