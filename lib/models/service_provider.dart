import 'dart:convert';

class ServiceProvider {
  final String id;
  final String description; 
  
  // Serviços e Preços
  final List<String> serviceTypes; 
  final Map<String, double> prices; 
  
  // Detalhes do Alojamento
  final String housingType; // 'Apartamento', 'Moradia', 'Quinta'
  final bool hasFencedYard;
  final bool hasYard;       
  final bool hasOtherPets;  
  
  // NOVOS CAMPOS
  final List<String> acceptedPets; // ['Cães', 'Gatos']
  final List<String> skills;       // ['Primeiros Socorros', 'Treino']
  
  // Logística
  final int serviceRadiusKm;
  final bool hasEmergencyTransport;

  // Galeria e Estado
  final List<String> gallery; 
  final bool isActive;        
  final int yearsExperience;
  
  // Estatísticas
  final double ratingAvg;
  final int ratingCount;

  // Localização (Cache opcional)
  final String? district;
  final String? municipality;
  final String? address;

  ServiceProvider({
    required this.id,
    required this.description,
    required this.serviceTypes,
    required this.prices,
    required this.housingType,
    required this.hasFencedYard,
    required this.hasYard,
    required this.hasOtherPets,
    required this.acceptedPets,
    required this.skills, // <--- NOVO
    required this.serviceRadiusKm,
    required this.hasEmergencyTransport,
    required this.gallery,
    required this.isActive,
    required this.yearsExperience,
    required this.ratingAvg,
    required this.ratingCount,
    this.district,
    this.municipality,
    this.address,
  });

  factory ServiceProvider.fromMap(Map<String, dynamic> map) {
    
    // 1. Tratamento seguro dos Preços
    Map<String, double> parsedPrices = {};
    if (map['prices'] != null) {
      final priceMap = map['prices'] is String 
          ? jsonDecode(map['prices']) 
          : map['prices'] as Map<String, dynamic>;

      priceMap.forEach((key, value) {
        parsedPrices[key] = (value is num) ? value.toDouble() : 0.0;
      });
    }

    // 2. Helper para Listas (Postgres Array -> List<String>)
    List<String> _parseList(dynamic listData) {
      if (listData == null) return [];
      // Se vier como String (JSON), faz decode. Se vier como List, converte.
      if (listData is String) {
         try {
           return List<String>.from(jsonDecode(listData));
         } catch (_) { return []; }
      }
      return List<String>.from(listData);
    }

    return ServiceProvider(
      id: map['id'] ?? '',
      description: map['description'] ?? map['bio'] ?? '', 
      
      serviceTypes: _parseList(map['service_types']),
      acceptedPets: _parseList(map['accepted_pets']),
      skills: _parseList(map['skills']), // <--- NOVO
      gallery: _parseList(map['gallery']),
      
      prices: parsedPrices,
      
      housingType: map['housing_type'] ?? 'Apartamento',
      hasFencedYard: map['has_fenced_yard'] ?? false,
      hasYard: map['has_yard'] ?? false,
      hasOtherPets: map['has_other_pets'] ?? false,
      
      serviceRadiusKm: map['service_radius_km'] ?? 10,
      hasEmergencyTransport: map['has_emergency_transport'] ?? false,

      isActive: map['is_active'] ?? true,
      yearsExperience: map['years_experience'] ?? 0,
      
      ratingAvg: (map['rating_avg'] ?? 0).toDouble(),
      ratingCount: map['rating_count'] ?? 0,
      
      district: map['district'], 
      municipality: map['municipality'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'service_types': serviceTypes,
      'prices': prices,
      'housing_type': housingType,
      'has_fenced_yard': hasFencedYard,
      'has_yard': hasYard,
      'has_other_pets': hasOtherPets,
      'accepted_pets': acceptedPets,
      'skills': skills, // <--- NOVO
      'service_radius_km': serviceRadiusKm,
      'has_emergency_transport': hasEmergencyTransport,
      'gallery': gallery,
      'is_active': isActive,
      'years_experience': yearsExperience,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'district': district,
      'municipality': municipality,
      'address': address,
    };
  }

  // --- HELPERS VISUAIS ---
  static String getServiceLabel(String key) {
    switch (key) {
      case 'pet_boarding': return 'Hospedagem Familiar';
      case 'pet_day_care': return 'Creche de Dia';
      case 'pet_sitting': return 'Pet Sitting (Domicílio)';
      case 'dog_walking': return 'Passeios';
      case 'pet_taxi': return 'Táxi Pet';
      case 'pet_grooming': return 'Banhos e Tosquias';
      case 'pet_training': return 'Treino';
      default: return key;
    }
  }

  static String getHousingLabel(String key) {
    switch (key) {
      case 'Apartamento': return 'Apartamento';
      case 'Moradia': return 'Moradia';
      case 'Quinta': return 'Quinta / Espaço Rural';
      default: return key;
    }
  }
}