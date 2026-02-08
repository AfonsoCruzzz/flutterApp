enum UserType {
  client,
  veterinarian,
  student,
  serviceProvider,
}

class User {
  final String id;
  final String email;
  final String name;
  final UserType type;
  final String? phone;
  final DateTime? createdAt;
  final String? photo;
  
  // NOVOS CAMPOS (Disponíveis para todos na hierarquia base)
  final String? district;
  final String? city;    // Concelho
  final String? address; // Morada

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.type,
    this.phone,
    this.createdAt,
    this.photo,
    this.district,
    this.city,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': type.name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'photo': photo,
      // Não esquecer de enviar isto de volta se necessário
      'district': district,
      'city': city,
      'address': address,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['full_name'] ?? map['name'] ?? '',
      type: _mapToUserType(map['role'] ?? map['type']),
      phone: map['phone'],
      photo: map['photo'],
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString()) 
          : null,
      
      // AQUI ESTÁ A CORREÇÃO DO ERRO VERMELHO:
      // Agora o User consegue ler estas colunas da tabela profiles
      district: map['district'],
      city: map['city'],
      address: map['address'],
    );
  }
}

// Helper seguro
UserType _mapToUserType(dynamic type) {
  if (type == null) return UserType.client;
  final stringType = type.toString().toLowerCase();
  
  switch (stringType) {
    case 'veterinarian': return UserType.veterinarian;
    case 'student': return UserType.student;
    case 'provider':
    case 'serviceprovider': return UserType.serviceProvider;
    default: return UserType.client;
  }
}