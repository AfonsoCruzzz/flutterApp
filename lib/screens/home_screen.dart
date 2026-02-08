import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

// Ecrãs de Navegação (Tabs)
import 'bookings_screen.dart';       // O ecrã onde aceitas/recusas pedidos
import 'conversations_screen.dart';  // Placeholder de Chat
import 'profile_screen.dart';        // Perfil
import 'add_animal_screen.dart';     // Botão central

// Ecrãs de Serviços (Navegação interna da Home)
import 'pet_sitting_screen.dart';
import 'veterinarians_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Controla qual aba está ativa

  // Cores da Marca
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  // Lógica de Navegação da Navbar
  void _onItemTapped(int index) {
    // Se clicar no botão do meio (índice 2), abre o modal de adicionar animal
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddAnimalScreen()),
      );
      return; 
    }
    
    // Caso contrário, troca de aba
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Aceder ao Provider
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Definir as Vistas para cada Aba
    final List<Widget> tabs = [
      // ABA 0: EXPLORAR (Home renovada)
      _buildExploreView(context, user),
      
      // ABA 1: RESERVAS
      const BookingsScreen(),
      
      // ABA 2: Placeholder (Botão Add - nunca é renderizado aqui)
      const SizedBox(), 
      
      // ABA 3: MENSAGENS
      const ConversationsScreen(),
      
      // ABA 4: PERFIL
      const ProfileScreen(isMyProfile: true),
    ];

    return Scaffold(
      // Renderiza apenas a aba selecionada
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      
      // 3. BARRA DE NAVEGAÇÃO (O Footer)
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: primaryPurple.withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 10,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: Color(0xFF6A1B9A)),
              label: 'Explorar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF6A1B9A)),
              label: 'Reservas',
            ),
            
            // BOTÃO CENTRAL DESTAQUE (+)
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: '',
              // REMOVI A LINHA: enabled: false 
              // Agora o botão já recebe o clique!
            ),

            const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF6A1B9A)),
              label: 'Mensagens',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF6A1B9A)),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTEÚDO DA ABA EXPLORAR (Renovado) ---
  Widget _buildExploreView(BuildContext context, User user) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NinaVets',
          style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Sem seta de voltar na Home
        actions: [
          // Botão Logout
          IconButton(
            icon: Icon(Icons.logout, color: primaryPurple),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                context.read<UserProvider>().clearUser();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao sair: $e")));
                }
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cartão de Boas Vindas
            _buildWelcomeHeader(user),
            
            const SizedBox(height: 30),

            Text(
              'O que procura hoje?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            
            // --- LISTA DE SERVIÇOS (Layout Vertical) ---
            
            // 1. Veterinários (Roxo)
            _buildHorizontalCard(
              context,
              title: 'Veterinários & Clínicas',
              subtitle: 'Marque consultas, vacinas e urgências.',
              icon: Icons.medical_services,
              color: primaryPurple,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VeterinariansScreen()));
              },
            ),

            const SizedBox(height: 16),

            // 2. Pet Sitting (Laranja) - Engloba passeios
            _buildHorizontalCard(
              context,
              title: 'Pet Sitting & Passeios',
              subtitle: 'Hospedagem, visitas ao domicílio e passeios.',
              icon: Icons.pets,
              color: primaryOrange,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PetSittingScreen()));
              },
            ),

            const SizedBox(height: 16),

            // 3. Cartões Condicionais (Role-based)
            if (user.type == UserType.veterinarian)
              _buildHorizontalCard(
                context,
                title: 'Chamar Estudante',
                subtitle: 'Precisa de ajuda na clínica?',
                icon: Icons.school,
                color: primaryPurple, // Volta ao Roxo para alternar
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve: Procurar Estudantes')));
                },
              ),

            if (user.type == UserType.student)
              _buildHorizontalCard(
                context,
                title: 'Oportunidades de Estágio',
                subtitle: 'Encontre clínicas para aprender.',
                icon: Icons.work,
                color: primaryPurple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve: Vagas de Estágio')));
                },
              ),
              
            // Espaço extra no fundo para não ficar colado à navbar
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildWelcomeHeader(User user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getWelcomeMessage(user),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryPurple),
              ),
              const SizedBox(height: 4),
              Text(
                'Perfil: ${_getUserTypeText(user)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Novo Widget de Cartão Horizontal (Mais elegante para lista vertical)
  Widget _buildHorizontalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone com fundo colorido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            // Seta
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _getWelcomeMessage(User user) {
    // Pega apenas o primeiro nome para ser mais pessoal
    final firstName = user.name.split(' ')[0];
    switch (user.type) {
      case UserType.veterinarian: return 'Olá, Dr(a). $firstName';
      case UserType.student: return 'Olá, $firstName';
      case UserType.serviceProvider: return 'Olá, $firstName';
      default: return 'Olá, $firstName';
    }
  }

  String _getUserTypeText(User user) {
    switch (user.type) {
      case UserType.veterinarian: return 'Veterinário';
      case UserType.student: return 'Estudante Vet';
      case UserType.serviceProvider: return 'Prestador';
      default: return 'Tutor / Cliente';
    }
  }
}