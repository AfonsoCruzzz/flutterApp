class Conversation {
  final String id;
  final String userA;
  final String userB;
  final String? lastMessage;
  final DateTime updatedAt;
  
  // Dados extra para a UI (Nome/Foto do outro user)
  final String? otherUserName;
  final String? otherUserPhoto;

  Conversation({
    required this.id,
    required this.userA,
    required this.userB,
    this.lastMessage,
    required this.updatedAt,
    this.otherUserName,
    this.otherUserPhoto,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String myId) {
    // Lógica para descobrir quem é o "outro"
    final isImUserA = map['user_a'] == myId;
    final otherData = isImUserA ? map['profile_b'] : map['profile_a'];

    return Conversation(
      id: map['id'],
      userA: map['user_a'],
      userB: map['user_b'],
      lastMessage: map['last_message'],
      updatedAt: DateTime.parse(map['updated_at']),
      otherUserName: otherData != null ? otherData['full_name'] : 'Utilizador',
      otherUserPhoto: otherData != null ? otherData['photo'] : null,
    );
  }
}