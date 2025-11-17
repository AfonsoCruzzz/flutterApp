import 'package:flutter/material.dart';

class PetSittingScreen extends StatefulWidget {
  const PetSittingScreen({super.key});

  @override
  State<PetSittingScreen> createState() => _PetSittingScreenState();
}

class _PetSittingScreenState extends State<PetSittingScreen> {
  int _selectedCategory = 0;
  int _currentIndex = 1;

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);
  final Color lightOrange = const Color(0xFFFFE8E0);
  final Color lightPurple = const Color(0xFFF3E5F5);

  final List<String> categories = ['Todos', 'Cães', 'Gatos', 'Aves', 'Peixes'];
  
  final List<Map<String, dynamic>> petSitters = [
    {
      'name': 'Maria Silva',
      'rating': 4.9,
      'location': 'Jardins, SP',
      'animals': ['Cães', 'Gatos'],
      'services': ['Passeios'],
      'reviews': 127,
      'price': 80.0,
    },
    {
      'name': 'João Santos',
      'rating': 4.7,
      'location': 'Centro, SP',
      'animals': ['Cães'],
      'services': ['Passeios', 'Hospedagem'],
      'reviews': 89,
      'price': 70.0,
    },
    {
      'name': 'Ana Costa',
      'rating': 5.0,
      'location': 'Vila Madalena, SP',
      'animals': ['Cães', 'Gatos', 'Aves'],
      'services': ['Passeios', 'Visitas'],
      'reviews': 203,
      'price': 90.0,
    },
  ];

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildCategoryChips(),
            const SizedBox(height: 24),
            _buildPopularSection(),
            const SizedBox(height: 16),
            _buildPetSittersList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightPurple),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por localização ou nome...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: primaryPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: _selectedCategory == index,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = index;
                });
              },
              selectedColor: primaryOrange,
              backgroundColor: lightOrange,
              labelStyle: TextStyle(
                color: _selectedCategory == index ? Colors.white : primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mais Populares',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryPurple,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navegar para ver todos
          },
          child: Text(
            'Ver todos',
            style: TextStyle(
              color: primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetSittersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: petSitters.length,
      itemBuilder: (context, index) {
        final sitter = petSitters[index];
        return _buildPetSitterCard(sitter);
      },
    );
  }

  Widget _buildPetSitterCard(Map<String, dynamic> sitter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do pet sitter
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: lightPurple,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sitter['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: lightOrange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: primaryOrange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sitter['rating'].toString(),
                                  style: TextStyle(
                                    color: primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Localização
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sitter['location'],
                            style: TextStyle(
                              color: primaryPurple,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Animais e serviços
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...(sitter['animals'] as List<String>).map((animal) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: lightPurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                animal,
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          ...(sitter['services'] as List<String>).map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: lightOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                  color: primaryOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Avaliações
                      Text(
                        '${sitter['reviews']} avaliações',
                        style: TextStyle(
                          color: primaryPurple,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Preço e botão
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '€${sitter['price']}/dia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showBookingDialog(sitter);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reservar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      selectedItemColor: primaryOrange, // Laranja para itens selecionados
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
        Navigator.pop(context); // Volta para home
        break;
      case 2:
        // Navigator.push(...); para Reservas
        break;
      case 3:
        // Navigator.push(...); para Mensagens
        break;
      case 4:
        // Navigator.push(...); para Perfil
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Funcionalidade de reserva em desenvolvimento...'),
            SizedBox(height: 16),
            Text('Aqui podes adicionar:'),
            Text('- Seleção de datas'),
            Text('- Escolha de serviços'),
            Text('- Confirmação de pagamento'),
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
            ),
            child: const Text('Reservar Agora'),
          ),
        ],
      ),
    );
  }
}