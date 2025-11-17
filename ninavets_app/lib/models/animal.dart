class Behavior {
  final bool anxious;
  final bool aggressive;
  final String specialNotes;

  Behavior({
    required this.anxious,
    required this.aggressive,
    required this.specialNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'anxious': anxious,
      'aggressive': aggressive,
      'specialNotes': specialNotes,
    };
  }

  factory Behavior.fromMap(Map<String, dynamic> map) {
    return Behavior(
      anxious: map['anxious'] ?? false,
      aggressive: map['aggressive'] ?? false,
      specialNotes: map['specialNotes'] ?? '',
    );
  }
}

class Animal {
  final String id;
  final String name;
  final String ownerId;
  final String species;
  final String breed;
  final DateTime? birthDate;
  final double? weight;
  final List<String> medicalConditions;
  final List<String> medications;
  final List<String> allergies;
  final List<String> surgicalHistory;
  final Behavior behavior;
  final DateTime createdAt;

  Animal({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.species,
    required this.breed,
    this.birthDate,
    this.weight,
    required this.medicalConditions,
    required this.medications,
    required this.allergies,
    required this.surgicalHistory,
    required this.behavior,
    required this.createdAt,
  });

  // Calcular idade aproximada
  int? get ageInYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year - birthDate!.year;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'species': species,
      'breed': breed,
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'weight': weight,
      'medicalConditions': medicalConditions,
      'medications': medications,
      'allergies': allergies,
      'surgicalHistory': surgicalHistory,
      'behavior': behavior.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      species: map['species'] ?? '',
      breed: map['breed'] ?? '',
      birthDate: map['birthDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['birthDate'])
          : null,
      weight: map['weight']?.toDouble(),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      surgicalHistory: List<String>.from(map['surgicalHistory'] ?? []),
      behavior: Behavior.fromMap(map['behavior'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}