import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../models/user.dart';
import 'pet_sitting_screen.dart';
import 'veterinarians_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);
  final Color lightOrange = const Color(0xFFFFE8E0);
  final Color lightPurple = const Color(0xFFF3E5F5);

  String _getWelcomeMessage() {
    switch (user.type) {
      case UserType.veterinarian:
        return 'Bem-vindo, Doutor(a) ${user.name}';
      case UserType.student:
        return 'Bem-vindo, Estudante ${user.name}';
      case UserType.serviceProvider:
        return 'Bem-vindo, Prestador ${user.name}';
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
      case UserType.serviceProvider:
        return 'Prestador de Serviços';
      default:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NinaVets - Home',
          style: TextStyle(color: primaryPurple),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryPurple),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: primaryPurple),
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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getWelcomeMessage(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
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
            
            Text(
              'Serviços Disponíveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
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
                    context,
                    'Veterinários',
                    Icons.medical_services,
                    primaryPurple,
                  ),
                  _buildServiceCard(
                    context,
                    'Passear',
                    Icons.directions_walk,
                    primaryOrange,
                  ),
                  _buildServiceCard(
                    context,
                    'Pet Sitting',
                    Icons.home,
                    primaryPurple,
                  ),
                  if (user.type == UserType.veterinarian)
                    _buildServiceCard(
                      context,
                      'Chamar Estudante',
                      Icons.school,
                      primaryOrange,
                    ),
                  if (user.type == UserType.student)
                    _buildServiceCard(
                      context,
                      'Oportunidades',
                      Icons.work,
                      primaryPurple,
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
          if (title == 'Pet Sitting') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PetSittingScreen()),
            );
          } else if (title == 'Veterinários') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VeterinariansScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Clicou em: $title'),
                backgroundColor: primaryOrange,
              ),
            );
          }
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}