import 'package:flutter/material.dart';
import './pet_sitting_search_screen.dart';
import '../widgets/pet_sitter_card.dart';

class PetSittingScreen extends StatefulWidget {
  const PetSittingScreen({super.key});

  @override
  State<PetSittingScreen> createState() => _PetSittingScreenState();
}

class _PetSittingScreenState extends State<PetSittingScreen> {
  int _currentIndex = 1;
  
  // Filtros ativos
  Map<String, dynamic> _activeFilters = {
    'searchQuery': '',
    'species': <String>[],
    'services': <String>[],
    'maxPrice': 100.0,
  };

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  // Lista completa de pet sitters
  final List<Map<String, dynamic>> _allPetSitters = [
    {
      'id': '1',
      'name': 'Maria Silva',
      'rating': 4.9,
      'location': 'Jardins, SP',
      'animals': ['Cães', 'Gatos'],
      'services': ['Passeios', 'Visitas'],
      'reviews': 127,
      'price': 80.0,
      'image': null,
    },
    {
      'id': '2',
      'name': 'João Santos',
      'rating': 4.7,
      'location': 'Centro, SP',
      'animals': ['Cães'],
      'services': ['Passeios', 'Hospedagem'],
      'reviews': 89,
      'price': 70.0,
      'image': null,
    },
    {
      'id': '3',
      'name': 'Ana Costa',
      'rating': 5.0,
      'location': 'Vila Madalena, SP',
      'animals': ['Cães', 'Gatos', 'Aves'],
      'services': ['Passeios', 'Visitas', 'Creche'],
      'reviews': 203,
      'price': 90.0,
      'image': null,
    },
    {
      'id': '4',
      'name': 'Pedro Oliveira',
      'rating': 4.8,
      'location': 'Copacabana, RJ',
      'animals': ['Peixes', 'Répteis'],
      'services': ['Consultoria', 'Hospedagem'],
      'reviews': 56,
      'price': 110.0,
      'image': null,
    },
    {
      'id': '5',
      'name': 'Carla Mendes',
      'rating': 4.6,
      'location': 'Moema, SP',
      'animals': ['Cães', 'Gatos', 'Roedores'],
      'services': ['Passeios', 'Adestramento', 'Creche'],
      'reviews': 78,
      'price': 85.0,
      'image': null,
    },
  ];

  // Lista filtrada
  List<Map<String, dynamic>> get _filteredPetSitters {
    return _allPetSitters.where((sitter) {
      // Filtro por busca
      final bool matchesSearch = _activeFilters['searchQuery'].isEmpty ||
          sitter['name'].toLowerCase().contains(_activeFilters['searchQuery'].toLowerCase()) ||
          sitter['location'].toLowerCase().contains(_activeFilters['searchQuery'].toLowerCase());

      // Filtro por espécies
      final List<String> selectedSpecies = List<String>.from(_activeFilters['species'] ?? []);
      final bool matchesSpecies = selectedSpecies.isEmpty ||
          selectedSpecies.any((species) => sitter['animals'].contains(species));

      // Filtro por serviços
      final List<String> selectedServices = List<String>.from(_activeFilters['services'] ?? []);
      final bool matchesServices = selectedServices.isEmpty ||
          selectedServices.any((service) => sitter['services'].contains(service));

      // Filtro por preço
      final bool matchesPrice = sitter['price'] <= (_activeFilters['maxPrice'] ?? 100.0);

      return matchesSearch && matchesSpecies && matchesServices && matchesPrice;
    }).toList();
  }

  // Método para navegar para a tela de pesquisa e aguardar os filtros
  Future<void> _openFilterScreen() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetSittingSearchScreen(
          initialFilters: _activeFilters,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pet Sitters',
          style: TextStyle(
            color: primaryPurple,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryPurple),
        actions: [
          IconButton(
            onPressed: _openFilterScreen,
            icon: Icon(Icons.filter_list),
            color: primaryPurple,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar resumo dos filtros ativos (opcional)
          if (_activeFilters['searchQuery'].isNotEmpty ||
              (_activeFilters['species'] as List).isNotEmpty ||
              (_activeFilters['services'] as List).isNotEmpty ||
              _activeFilters['maxPrice'] != 100.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getActiveFiltersSummary(),
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeFilters = {
                          'searchQuery': '',
                          'species': <String>[],
                          'services': <String>[],
                          'maxPrice': 100.0,
                        };
                      });
                    },
                    child: Text(
                      'Limpar',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ),
                ],
              ),
            ),
          
          // Header da lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPetSitters.length} pet sitters encontrados',
                  style: TextStyle(
                    color: primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: _filteredPetSitters.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPetSitters.length,
                    itemBuilder: (context, index) {
                      final sitter = _filteredPetSitters[index];
                      return PetSitterCard(
                        sitter: sitter,
                        onBook: () => _showBookingDialog(sitter),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getActiveFiltersSummary() {
    List<String> active = [];
    if (_activeFilters['searchQuery'].isNotEmpty) {
      active.add('"${_activeFilters['searchQuery']}"');
    }
    if ((_activeFilters['species'] as List).isNotEmpty) {
      active.add('Espécies: ${(_activeFilters['species'] as List).join(', ')}');
    }
    if ((_activeFilters['services'] as List).isNotEmpty) {
      active.add('Serviços: ${(_activeFilters['services'] as List).join(', ')}');
    }
    if (_activeFilters['maxPrice'] != 100.0) {
      active.add('Até R\$${_activeFilters['maxPrice']}');
    }
    return 'Filtros: ${active.join(' • ')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum pet sitter encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros de pesquisa',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openFilterScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
            ),
            child: const Text('Abrir Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        _navigateToScreen(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryOrange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Reservas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Mensagens',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 2:
        // TODO: Navegar para Reservas
        break;
      case 3:
        // TODO: Navegar para Mensagens
        break;
      case 4:
        // TODO: Navegar para Perfil
        break;
    }
  }

  void _showBookingDialog(Map<String, dynamic> sitter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reservar com ${sitter['name']}',
          style: TextStyle(color: primaryPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preço: R\$${sitter['price']}/dia',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Localização: ${sitter['location']}'),
            const SizedBox(height: 8),
            Text('Avaliação: ⭐ ${sitter['rating']} (${sitter['reviews']} reviews)'),
            const SizedBox(height: 16),
            const Text('Funcionalidade de reserva em desenvolvimento...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: TextStyle(color: primaryPurple),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reserva com ${sitter['name']} solicitada!'),
                  backgroundColor: primaryOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
            ),
            child: const Text('Solicitar Reserva'),
          ),
        ],
      ),
    );
  }
}