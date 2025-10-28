

class User {
  final String id;
  final String email;
  final String name;
  final UserType type;
  final String? phone;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.type,
    this.phone,
    this.createdAt,
  });

  // Converter para Map (para Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'type': type.toString().split('.').last,
      'phone': phone,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  // Criar User a partir de Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      type: _stringToUserType(map['type']),
      phone: map['phone'],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}

enum UserType {
  client,
  veterinarian,
  student,
  serviceProvider,
}

// Helper para converter string para UserType
UserType _stringToUserType(String type) {
  switch (type) {
    case 'veterinarian':
      return UserType.veterinarian;
    case 'student':
      return UserType.student;
    case 'serviceProvider':
      return UserType.serviceProvider;
    default:
      return UserType.client;
  }
}