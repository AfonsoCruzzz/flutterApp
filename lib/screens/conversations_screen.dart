import 'package:flutter/material.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mensagens"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF6A1B9A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "Ainda não tem mensagens.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Text(
              "Contacte um prestador para iniciar um chat.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}