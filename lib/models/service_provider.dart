import 'dart:convert';
import 'working_schedule.dart'; // <--- IMPORTANTE: Importar o modelo do horário

class ServiceProvider {
  final String id;
  final String description; 
  
  // Serviços e Preços
  final List<String> serviceTypes; 
  final Map<String, double> prices; 
  
  // Detalhes do Alojamento
  final String housingType;
  final bool hasFencedYard;
  final bool hasYard;       
  final bool hasOtherPets;  
  
  // Listas
  final List<String> acceptedPets;
  final List<String> skills;
  
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

  // Localização
  final String? district;
  final String? municipality;
  final String? address;

  // --- NOVO CAMPO: HORÁRIO ---
  final WorkingSchedule? schedule; 

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
    required this.skills,
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
    // Adicionar ao construtor
    this.schedule, 
  });

  // Método essencial para atualizações instantâneas
  ServiceProvider copyWith({
    String? id,
    String? description,
    List<String>? serviceTypes,
    Map<String, double>? prices,
    String? housingType,
    bool? hasFencedYard,
    bool? hasYard,
    bool? hasOtherPets,
    List<String>? acceptedPets,
    List<String>? skills,
    int? serviceRadiusKm,
    bool? hasEmergencyTransport,
    List<String>? gallery,
    bool? isActive, // <--- O campo que queremos mudar
    int? yearsExperience,
    double? ratingAvg,
    int? ratingCount,
    String? district,
    String? municipality,
    String? address,
    WorkingSchedule? schedule,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      description: description ?? this.description,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      prices: prices ?? this.prices,
      housingType: housingType ?? this.housingType,
      hasFencedYard: hasFencedYard ?? this.hasFencedYard,
      hasYard: hasYard ?? this.hasYard,
      hasOtherPets: hasOtherPets ?? this.hasOtherPets,
      acceptedPets: acceptedPets ?? this.acceptedPets,
      skills: skills ?? this.skills,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      hasEmergencyTransport: hasEmergencyTransport ?? this.hasEmergencyTransport,
      gallery: gallery ?? this.gallery,
      isActive: isActive ?? this.isActive,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
    );
  }

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

    // 2. Helper para Listas
    List<String> _parseList(dynamic listData) {
      if (listData == null) return [];
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
      skills: _parseList(map['skills']), 
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

      // --- NOVO: Converter JSONB para Objeto Schedule ---
      schedule: map['working_schedule'] != null 
          ? WorkingSchedule.fromMap(map['working_schedule'])
          : WorkingSchedule.empty(),
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
      'skills': skills,
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
      
      // --- NOVO: Converter Objeto Schedule para JSON ---
      'working_schedule': schedule?.toMap(),
    };
  }

  // --- HELPERS VISUAIS MANTÊM-SE IGUAIS ---
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