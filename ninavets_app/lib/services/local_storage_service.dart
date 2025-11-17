import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String _usersBoxName = 'usersBox';
  static const String _veterinariansBoxName = 'veterinariansBox';
  static const String _animalsBoxName = 'animalsBox';

  static Box<Map>? _usersBox;
  static Box<Map>? _veterinariansBox;
  static Box<Map>? _animalsBox;
  static bool _hiveInitialized = false;

  static Future<void> init() async {
    if (!_hiveInitialized) {
      await Hive.initFlutter();
      
      // Registar os adaptadores (vamos criar depois)
      // Hive.registerAdapter(CoordinatesAdapter());
      // Hive.registerAdapter(VeterinarianAdapter());
      // Hive.registerAdapter(AnimalAdapter());
      
      _hiveInitialized = true;
    }

    // Inicializar todas as boxes
    _usersBox = await Hive.openBox<Map>(_usersBoxName);
    _veterinariansBox = await Hive.openBox<Map>(_veterinariansBoxName);
    _animalsBox = await Hive.openBox<Map>(_animalsBoxName);
    
    // Inserir dados de demonstração
    await _insertDemoData();
  }

  static Future<Box<Map>> usersBox() async {
    if (_usersBox == null || !_usersBox!.isOpen) {
      await init();
    }
    return _usersBox!;
  }

  static Future<Box<Map>> veterinariansBox() async {
    if (_veterinariansBox == null || !_veterinariansBox!.isOpen) {
      await init();
    }
    return _veterinariansBox!;
  }

  static Future<Box<Map>> animalsBox() async {
    if (_animalsBox == null || !_animalsBox!.isOpen) {
      await init();
    }
    return _animalsBox!;
  }

  static Future<void> _insertDemoData() async {
    final vetBox = await veterinariansBox();
    
      // Veterinários de demonstração
    final demoVeterinarians = [
      {
        'id': '1',
        'name': 'Dra. Ana Costa',
        'licenseNumber': 'VET12345',
        'email': 'ana.costa@vet.pt',
        'phone': '+351912345670',
        'bio': 'Especialista em cardiologia veterinária com 10 anos de experiência.',
        'species': ['Cão', 'Gato'],
        'specialties': ['Cardiologia', 'Clínica Geral'],
        'services': ['Consulta', 'Urgência', 'Ecografia'],
        'availability': {
          'emergency': true,
          'homeVisit': true,
          'weekends': false,
          'businessHours': {'start': '09:00', 'end': '18:00'}
        },
        'location': {
          'address': 'Rua das Flores, 123',
          'city': 'Lisboa',
          'coordinates': {'lat': 38.7223, 'lng': -9.1393}
        },
        'rating': {'average': 4.8, 'reviews': 127},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': '2',
        'name': 'Dr. Miguel Santos',
        'licenseNumber': 'VET12346',
        'email': 'miguel.santos@vet.pt',
        'phone': '+351912345671',
        'bio': 'Especialista em dermatologia e alergias.',
        'species': ['Cão', 'Gato', 'Aves'],
        'specialties': ['Dermatologia', 'Alergologia'],
        'services': ['Consulta', 'Domicílio', 'Testes Alérgicos'],
        'availability': {
          'emergency': false,
          'homeVisit': true,
          'weekends': true,
          'businessHours': {'start': '10:00', 'end': '19:00'}
        },
        'location': {
          'address': 'Avenida da Liberdade, 456',
          'city': 'Porto',
          'coordinates': {'lat': 41.1579, 'lng': -8.6291}
        },
        'rating': {'average': 4.6, 'reviews': 89},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      }
    ];

    for (final vet in demoVeterinarians) {
      await vetBox.put(vet['id'], vet);
    }
  }

  static Future<void> close() async {
    await _usersBox?.close();
    await _veterinariansBox?.close();
    await _animalsBox?.close();
  }
}