import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/user_provider.dart';
import '../models/conversation.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<UserProvider>().currentUser?.id;
    if (myId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    const Color primaryPurple = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mensagens"),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Query complexa: Vai buscar as conversas e faz join com os profiles de A e B
        stream: _supabase
            .from('conversations')
            .stream(primaryKey: ['id'])
            .order('updated_at', ascending: false)
            .map((data) => data), // Truque para o StreamBuilder funcionar
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Nota: O StreamBuilder do Supabase não suporta Joins profundos facilmente.
          // Para listas de conversas, o ideal é fazer um Fetch normal no init e ouvir mudanças,
          // ou usar Views SQL.
          // Para simplificar, vamos fazer um FutureBuilder dentro do builder para ir buscar os nomes.
          // No entanto, para performance, aqui fica uma abordagem híbrida:
          
          final conversationIds = snapshot.data!.map((e) => e['id']).toList();
          
          if (conversationIds.isEmpty) {
             return _buildEmptyState();
          }

          return FutureBuilder(
            // Buscar detalhes completos (nomes/fotos) agora que temos os IDs
            future: _supabase
                .from('conversations')
                .select('*, profile_a:profiles!user_a(full_name, photo), profile_b:profiles!user_b(full_name, photo)')
                .inFilter('id', conversationIds)
                .order('updated_at', ascending: false),
            builder: (context, AsyncSnapshot<List<dynamic>> fullDataSnapshot) {
               if (!fullDataSnapshot.hasData) return const Center(child: CircularProgressIndicator());
               
               final conversations = fullDataSnapshot.data!.map((m) => Conversation.fromMap(m, myId)).toList();

               return ListView.separated(
                 padding: const EdgeInsets.all(16),
                 itemCount: conversations.length,
                 separatorBuilder: (c, i) => const Divider(height: 1),
                 itemBuilder: (context, index) {
                   final chat = conversations[index];
                   
                   return ListTile(
                     contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     leading: CircleAvatar(
                       radius: 28,
                       backgroundColor: Colors.grey[200],
                       backgroundImage: chat.otherUserPhoto != null ? NetworkImage(chat.otherUserPhoto!) : null,
                       child: chat.otherUserPhoto == null ? const Icon(Icons.person, color: Colors.grey) : null,
                     ),
                     title: Text(chat.otherUserName ?? 'Utilizador', style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text(
                       chat.lastMessage ?? 'Inicie a conversa...', 
                       maxLines: 1, 
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(color: chat.lastMessage == null ? primaryPurple : Colors.grey[600]),
                     ),
                     trailing: Text(
                       timeago.format(chat.updatedAt, locale: 'pt'), // Podes configurar PT no main
                       style: const TextStyle(fontSize: 12, color: Colors.grey),
                     ),
                     onTap: () {
                       // Abrir Chat
                       Navigator.push(
                         context, 
                         MaterialPageRoute(builder: (_) => ChatScreen(
                           conversationId: chat.id,
                           otherUserId: chat.userA == myId ? chat.userB : chat.userA,
                           otherUserName: chat.otherUserName ?? 'Chat',
                           otherUserPhoto: chat.otherUserPhoto,
                         ))
                       );
                     },
                   );
                 },
               );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Sem conversas ativas.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}