import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/user.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  String _getWelcomeMessage() {
    switch (user.type) {
      case UserType.veterinarian:
        return 'Bem-vindo, Doutor(a) ${user.name}';
      case UserType.student:
        return 'Bem-vindo, Estudante ${user.name}';
      case UserType.client: // Corrigido
        return 'Bem-vindo, Cliente ${user.name}';
      default:
        return 'Bem-vindo, ${user.name}';
    }
  }

  String _getUserTypeText() {
    switch (user.type) {
      case UserType.veterinarian:
        return 'Veterinário';
      case UserType.student:
        return 'Estudante de Veterinária';
      case UserType.client: // Corrigido
        return 'Cliente';
      default:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NinaVets - Home'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informação do utilizador
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getWelcomeMessage(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tipo: ${_getUserTypeText()}'),
                    Text('Email: ${user.email}'),
                    if (user.phone != null) Text('Telefone: ${user.phone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Serviços Disponíveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione o serviço que precisa',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Cards de Serviços
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildServiceCard(
                    context, // ⬅️ PASSA O CONTEXT AQUI
                    'Veterinários',
                    Icons.medical_services,
                    Colors.green,
                  ),
                  _buildServiceCard(
                    context, // ⬅️ PASSA O CONTEXT AQUI
                    'Passear',
                    Icons.directions_walk,
                    Colors.orange,
                  ),
                  _buildServiceCard(
                    context, // ⬅️ PASSA O CONTEXT AQUI
                    'Pet Sitting',
                    Icons.home,
                    Colors.purple,
                  ),
                  if (user.type == UserType.veterinarian)
                    _buildServiceCard(
                      context, // ⬅️ PASSA O CONTEXT AQUI
                      'Chamar Estudante',
                      Icons.school,
                      Colors.blue,
                    ),
                  if (user.type == UserType.student)
                    _buildServiceCard(
                      context, // ⬅️ PASSA O CONTEXT AQUI
                      'Oportunidades',
                      Icons.work,
                      Colors.blue,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Agora o context está disponível porque recebemos como parâmetro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Clicou em: $title')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}