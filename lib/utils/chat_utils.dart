import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/chat_screen.dart';

class ChatUtils {
  static Future<void> openChat(BuildContext context, {
    required String targetUserId, 
    required String targetUserName, 
    String? targetUserPhoto
  }) async {
    final supabase = Supabase.instance.client;
    final myId = supabase.auth.currentUser?.id;

    if (myId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faça login para enviar mensagens.")));
      return;
    }

    if (myId == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não pode enviar mensagens a si próprio.")));
      return;
    }

    // Mostrar loading
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. Verificar se já existe conversa
      // Procuramos onde (user_a = eu E user_b = ele) OU (user_a = ele E user_b = eu)
      final response = await supabase.from('conversations')
          .select()
          .or('and(user_a.eq.$myId,user_b.eq.$targetUserId),and(user_a.eq.$targetUserId,user_b.eq.$myId)')
          .maybeSingle();

      String conversationId;

      if (response != null) {
        // Já existe
        conversationId = response['id'];
      } else {
        // 2. Não existe, criar nova
        final newChat = await supabase.from('conversations').insert({
          'user_a': myId,
          'user_b': targetUserId,
          'last_message': null, // Começa vazia
        }).select().single();
        
        conversationId = newChat['id'];
      }

      if (context.mounted) {
        Navigator.pop(context); // Fechar loading
        
        // Abrir ecrã de chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              otherUserId: targetUserId,
              otherUserName: targetUserName,
              otherUserPhoto: targetUserPhoto,
            ),
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao iniciar chat: $e")));
      }
    }
  }
}