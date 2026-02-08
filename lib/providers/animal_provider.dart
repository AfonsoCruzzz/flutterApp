import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';

class AnimalProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<Animal> _myAnimals = [];
  bool _isLoading = false;

  List<Animal> get myAnimals => _myAnimals;
  bool get isLoading => _isLoading;

  Future<void> loadAnimals(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('animals')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      _myAnimals = (response as List).map((data) => Animal.fromMap(data)).toList();
    } catch (e) {
      print('Erro ao carregar animais: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAnimal(Animal animal, String userId) async {
    try {
      final response = await _supabase
          .from('animals')
          .insert(animal.toMap())
          .select()
          .single();
      
      final newAnimal = Animal.fromMap(response);
      _myAnimals.insert(0, newAnimal); // Adiciona ao topo da lista localmente
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar animal: $e');
      rethrow;
    }
  }

  Future<void> updateAnimal(Animal animal) async {
    try {
      // O toMap já tem os dados todos. O ID garante que atualizamos o certo.
      final response = await _supabase
          .from('animals')
          .update(animal.toMap())
          .eq('id', animal.id) // <--- O segredo está aqui: filtro pelo ID
          .select()
          .single();

      // Atualizar a lista localmente para a UI mudar logo sem recarregar tudo
      final updatedAnimal = Animal.fromMap(response);
      final index = _myAnimals.indexWhere((a) => a.id == animal.id);
      if (index != -1) {
        _myAnimals[index] = updatedAnimal;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar animal: $e');
      rethrow;
    }
  }
}