class Animal {
  final String id;
  final String ownerId;
  final String name;
  final String species; // dog, cat, etc.
  final String? breed;
  final String? gender;
  final double? weight;
  final DateTime? birthDate;
  final String? photo;
  final String? microchipNumber;
  final bool isSterilized;
  final bool isVaccinated;
  final String? behavioralNotes;
  final String? medicalNotes;

  Animal({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.weight,
    this.birthDate,
    this.photo,
    this.microchipNumber,
    this.isSterilized = false,
    this.isVaccinated = false,
    this.behavioralNotes,
    this.medicalNotes,
  });

  // Calcular idade dinamicamente
  int? get ageInYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
       (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      ownerId: map['owner_id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      gender: map['gender'],
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      photo: map['photo'],
      microchipNumber: map['microchip_number'],
      isSterilized: map['is_sterilized'] ?? false,
      isVaccinated: map['is_vaccinated'] ?? false,
      behavioralNotes: map['behavioral_notes'],
      medicalNotes: map['medical_notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId, // ID é gerado pelo Supabase se for null no insert
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'weight': weight,
      'birth_date': birthDate?.toIso8601String(),
      'photo': photo,
      'microchip_number': microchipNumber,
      'is_sterilized': isSterilized,
      'is_vaccinated': isVaccinated,
      'behavioral_notes': behavioralNotes,
      'medical_notes': medicalNotes,
    };
  }
}