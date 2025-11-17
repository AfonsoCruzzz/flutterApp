import 'coordinates.dart';

class BusinessHours {
  final String start;
  final String end;

  BusinessHours({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '18:00',
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'emergency': emergency,
      'homeVisit': homeVisit,
      'weekends': weekends,
      'businessHours': businessHours.toMap(),
    };
  }

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      emergency: map['emergency'] ?? false,
      homeVisit: map['homeVisit'] ?? false,
      weekends: map['weekends'] ?? false,
      businessHours: BusinessHours.fromMap(map['businessHours'] ?? {}),
    );
  }
}

class Location {
  final String address;
  final String city;
  final Coordinates coordinates;

  Location({
    required this.address,
    required this.city,
    required this.coordinates,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'coordinates': coordinates.toMap(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      coordinates: Coordinates.fromMap(map['coordinates'] ?? {}),
    );
  }
}

class Rating {
  final double average;
  final int reviews;

  Rating({
    required this.average,
    required this.reviews,
  });

  Map<String, dynamic> toMap() {
    return {
      'average': average,
      'reviews': reviews,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      average: map['average']?.toDouble() ?? 0.0,
      reviews: map['reviews']?.toInt() ?? 0,
    );
  }
}

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

  Veterinarian({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.email,
    required this.phone,
    this.photo,
    required this.bio,
    required this.species,
    required this.specialties,
    required this.services,
    required this.availability,
    required this.location,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'licenseNumber': licenseNumber,
      'email': email,
      'phone': phone,
      'photo': photo,
      'bio': bio,
      'species': species,
      'specialties': specialties,
      'services': services,
      'availability': availability.toMap(),
      'location': location.toMap(),
      'rating': rating.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Veterinarian.fromMap(Map<String, dynamic> map) {
    return Veterinarian(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photo: map['photo'],
      bio: map['bio'] ?? '',
      species: List<String>.from(map['species'] ?? []),
      specialties: List<String>.from(map['specialties'] ?? []),
      services: List<String>.from(map['services'] ?? []),
      availability: Availability.fromMap(map['availability'] ?? {}),
      location: Location.fromMap(map['location'] ?? {}),
      rating: Rating.fromMap(map['rating'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}