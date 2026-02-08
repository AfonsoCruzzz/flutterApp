import 'coordinates.dart';
import 'working_schedule.dart';

// --- Classes Auxiliares mantêm-se, mas com fromMap mais seguro ---

class BusinessHours {
  final String start;
  final String end;
  BusinessHours({required this.start, required this.end});
  
  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '18:00',
    );
  }
  Map<String, dynamic> toMap() => {'start': start, 'end': end};
}

class Availability {
  final bool emergency;
  final bool homeVisit;
  final bool weekends;
  final BusinessHours businessHours;

  Availability({
    required this.emergency,
    required this.homeVisit,
    required this.weekends,
    required this.businessHours,
  });

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      emergency: map['emergency'] ?? false,
      homeVisit: map['homeVisit'] ?? false,
      weekends: map['weekends'] ?? false,
      businessHours: BusinessHours.fromMap(map['businessHours'] ?? {}),
    );
  }
  Map<String, dynamic> toMap() => {
    'emergency': emergency,
    'homeVisit': homeVisit,
    'weekends': weekends,
    'businessHours': businessHours.toMap(),
  };
}

class Location {
  final String address;
  final String city;
  final Coordinates coordinates;

  Location({required this.address, required this.city, required this.coordinates});

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      coordinates: Coordinates.fromMap(map['coordinates'] ?? {}),
    );
  }
  Map<String, dynamic> toMap() => {
    'address': address,
    'city': city,
    'coordinates': coordinates.toMap(),
  };
}

class Rating {
  final double average;
  final int reviews;

  Rating({required this.average, required this.reviews});

  factory Rating.fromMap(Map<String, dynamic> map) {
    // Garante que converte int para double se necessário
    return Rating(
      average: (map['average'] ?? map['rating_avg'] ?? 0).toDouble(),
      reviews: (map['reviews'] ?? map['rating_count'] ?? 0).toInt(),
    );
  }
  Map<String, dynamic> toMap() => {'average': average, 'reviews': reviews};
}

// --- CLASSE PRINCIPAL ---

class Veterinarian {
  final String id;
  final String name;
  final String licenseNumber;
  final String email;
  final String phone;
  final String? photo;
  final String bio;
  final List<String> species;
  final List<String> specialties;
  final List<String> services;
  final Availability availability;
  final Location location;
  final Rating rating;
  final DateTime createdAt;
  final String? district; // Distrito
  final String? municipality; // Concelho
  final String? parish; // Freguesia
  final String serviceType; // 'clinic', 'independent', 'both'
  final bool hasOwnSpace;   // Atende no seu espaço?
  final bool doesHomeVisits;
  final String? clinicName;
  final bool isMobile;
  final bool isVerified;
  final bool isActive;
  final WorkingSchedule? schedule;


  Veterinarian({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.email,
    required this.phone,
    this.photo,
    this.district,
    this.municipality,
    this.parish,
    this.clinicName,
    this.isMobile = false,
    this.isVerified = false,
    required this.bio,
    required this.species,
    required this.specialties,
    required this.services,
    required this.availability,
    required this.location,
    required this.rating,
    required this.createdAt,
    this.serviceType = 'clinic',
    this.hasOwnSpace = false,
    this.doesHomeVisits = false,
    this.isActive = true,
    this.schedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'license_number': licenseNumber, // snake_case
      'email': email,
      'phone': phone,
      'photo': photo,
      'bio': bio,
      'species': species,
      'specialties': specialties,
      'services': services,
      'availability': availability.toMap(),
      'location_data': location.toMap(), // Nome da coluna JSONB
      'rating_avg': rating.average,
      'rating_count': rating.reviews,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Veterinarian.fromMap(Map<String, dynamic> map) {
    // Tratamento seguro dos objetos aninhados
    final locMap = map['location_data'] ?? map['location'] ?? {};
    if (map['address'] != null) locMap['address'] = map['address'];
    if (map['city'] != null) locMap['city'] = map['city'];

    return Veterinarian(
      id: map['id'] ?? '',
      name: map['full_name'] ?? map['name'] ?? '',
      photo: map['photo'],
      
      district: map['district'],
      municipality: map['municipality'],
      parish: map['parish'],
      
      // Mapeamento dos novos campos
      serviceType: map['service_type'] ?? 'clinic',
      clinicName: map['clinic_name'],
      hasOwnSpace: map['has_own_space'] ?? false,
      doesHomeVisits: map['does_home_visits'] ?? false,

      licenseNumber: map['license_number'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      species: List<String>.from(map['species'] ?? []),
      specialties: List<String>.from(map['specialties'] ?? []),
      services: List<String>.from(map['services'] ?? []),
      availability: Availability.fromMap(map['availability'] ?? {}),
      location: Location.fromMap(locMap),
      rating: map['rating'] != null 
          ? Rating.fromMap(map['rating']) 
          : Rating(
              average: (map['rating_avg'] ?? 0).toDouble(),
              reviews: (map['rating_count'] ?? 0).toInt(),
            ),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isActive: map['is_active'] ?? true,
      isMobile: map['is_mobile'] ?? false,
      isVerified: map['is_verified'] ?? false,
      schedule: map['working_schedule'] != null 
          ? WorkingSchedule.fromMap(map['working_schedule'])
          : WorkingSchedule.empty(),
    );
  }
}