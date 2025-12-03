import 'package:flutter/material.dart';
import './veterinarians_filter_screen.dart';
import '../models/animal.dart';
import '../models/veterinarian.dart';
import '../services/animal_service.dart';
import '../services/veterinarian_service.dart';
import '../widgets/veterinarian_card.dart';

class VeterinariansScreen extends StatefulWidget {
  const VeterinariansScreen({super.key});

  @override
  State<VeterinariansScreen> createState() => _VeterinariansScreenState();
}

class _VeterinariansScreenState extends State<VeterinariansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Animal> _userAnimals = [];
  List<Veterinarian> _allVeterinarians = [];
  List<Veterinarian> _filteredVeterinarians = [];
  
  // Filtros ativos
  Map<String, dynamic> _activeFilters = {
    'species': <String>[],
    'specialties': <String>[],
    'services': <String>[],
    'location': {'postalCode': '', 'distance': 25},
    'availability': {'openNow': false, 'emergency24h': false},
  };
  
  Animal? _selectedAnimal;
  bool _isLoading = true;

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // TODO: Substituir '1' pelo ID do user logado
      final animals = await AnimalService.getAnimalsByOwner('1');
      final veterinarians = await VeterinarianService.getAllVeterinarians();
      
      setState(() {
        _userAnimals = animals;
        _allVeterinarians = veterinarians;
        _filteredVeterinarians = veterinarians;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro a carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilterScreen() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VeterinariansFilterScreen(
          initialFilters: _activeFilters,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Veterinarian> filtered = _allVeterinarians;

    // Converter explicitamente para List<String> antes de usar
    final List<String> selectedSpecies = List<String>.from(_activeFilters['species'] ?? []);
    final List<String> selectedSpecialties = List<String>.from(_activeFilters['specialties'] ?? []);
    final List<String> selectedServices = List<String>.from(_activeFilters['services'] ?? []);

    // Filtrar por espécies selecionadas
    if (selectedSpecies.isNotEmpty) {
      filtered = filtered.where((vet) => 
          selectedSpecies.any((species) => vet.species.contains(species))).toList();
    }

    // Filtrar por especialidades
    if (selectedSpecialties.isNotEmpty) {
      filtered = filtered.where((vet) => 
          selectedSpecialties.any((specialty) => vet.specialties.contains(specialty))).toList();
    }

    // Filtrar por serviços
    if (selectedServices.isNotEmpty) {
      filtered = filtered.where((vet) => 
          selectedServices.any((service) => vet.services.contains(service))).toList();
    }

    // Filtrar por disponibilidade
    if (_activeFilters['availability']['openNow'] == true) {
      final now = TimeOfDay.now();
      filtered = filtered.where((vet) {
        final start = _parseTime(vet.availability.businessHours.start);
        final end = _parseTime(vet.availability.businessHours.end);
        return now.hour >= start.hour && now.hour <= end.hour;
      }).toList();
    }

    if (_activeFilters['availability']['emergency24h'] == true) {
      filtered = filtered.where((vet) => vet.availability.emergency).toList();
    }

    setState(() {
      _filteredVeterinarians = filtered;
    });
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _onAnimalSelected(Animal? animal) {
    setState(() {
      _selectedAnimal = animal;
    });
  }

  bool _hasActiveFilters() {
    return (_activeFilters['species'] as List).isNotEmpty ||
        (_activeFilters['specialties'] as List).isNotEmpty ||
        (_activeFilters['services'] as List).isNotEmpty ||
        _activeFilters['location']['postalCode'].isNotEmpty ||
        _activeFilters['location']['distance'] != 25 ||
        _activeFilters['availability']['openNow'] ||
        _activeFilters['availability']['emergency24h'];
  }

  String _getActiveFiltersSummary() {
    List<String> active = [];
    if ((_activeFilters['species'] as List).isNotEmpty) {
      active.add('Espécies: ${(_activeFilters['species'] as List).join(', ')}');
    }
    if ((_activeFilters['specialties'] as List).isNotEmpty) {
      active.add('Especialidades: ${(_activeFilters['specialties'] as List).join(', ')}');
    }
    if ((_activeFilters['services'] as List).isNotEmpty) {
      active.add('Serviços: ${(_activeFilters['services'] as List).join(', ')}');
    }
    if (_activeFilters['location']['postalCode'].isNotEmpty) {
      active.add('Código Postal: ${_activeFilters['location']['postalCode']}');
    }
    if (_activeFilters['location']['distance'] != 25) {
      active.add('Raio: ${_activeFilters['location']['distance']} km');
    }
    if (_activeFilters['availability']['openNow']) {
      active.add('Aberto agora');
    }
    if (_activeFilters['availability']['emergency24h']) {
      active.add('Urgências 24h');
    }
    return 'Filtros: ${active.join(' • ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamar Veterinário'),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryPurple),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryOrange,
          tabs: const [
            Tab(text: 'Para uma necessidade específica'), // ABA ESQUERDA
            Tab(text: 'Para o meu animal'), // ABA DIREITA
          ],
          onTap: (index) {
            setState(() {});
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ABA 1: Para uma necessidade específica (COM LISTA DE VETERINÁRIOS)
                _buildForSpecificNeedTab(),
                // ABA 2: Para o meu animal (SEM LISTA DE VETERINÁRIOS)
                _buildForMyAnimalTab(),
              ],
            ),
    );
  }

  Widget _buildForSpecificNeedTab() {
    return Column(
      children: [
        // Cabeçalho com botão de filtro
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_filteredVeterinarians.length} veterinários encontrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openFilterScreen,
                icon: const Icon(Icons.filter_list),
                color: primaryPurple,
              ),
            ],
          ),
        ),
        // Mostrar resumo dos filtros ativos
        if (_hasActiveFilters())
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
                        'species': <String>[],
                        'specialties': <String>[],
                        'services': <String>[],
                        'location': {'postalCode': '', 'distance': 25},
                        'availability': {'openNow': false, 'emergency24h': false},
                      };
                    });
                    _applyFilters();
                  },
                  child: Text(
                    'Limpar',
                    style: TextStyle(color: primaryOrange),
                  ),
                ),
              ],
            ),
          ),
        // Lista de resultados
        Expanded(
          child: _filteredVeterinarians.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredVeterinarians.length,
                  itemBuilder: (context, index) {
                    return VeterinarianCard(
                      veterinarian: _filteredVeterinarians[index],
                      onCall: () => _onCallVeterinarian(_filteredVeterinarians[index]),
                      onChat: () => _onChatVeterinarian(_filteredVeterinarians[index]),
                      onBook: () => _onBookAppointment(_filteredVeterinarians[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildForMyAnimalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_userAnimals.isNotEmpty) ...[
            // Se o utilizador tem animais, mostrar dropdown
            const Text(
              'Selecione o seu animal:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6A1B9A), width: 1),
              ),
              child: DropdownButton<Animal>(
                value: _selectedAnimal,
                isExpanded: true,
                underline: const SizedBox(), // Remove a linha padrão
                hint: const Text('Selecione um animal'),
                items: _userAnimals.map((Animal animal) {
                  return DropdownMenuItem<Animal>(
                    value: animal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.pets, color: Color(0xFF6A1B9A)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${animal.species} • ${animal.breed.isNotEmpty ? animal.breed : "Raça não especificada"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onAnimalSelected,
              ),
            ),
            const SizedBox(height: 24),
            // Mostrar informações do animal selecionado
            if (_selectedAnimal != null) _buildAnimalInfoCard(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
          ],
          // Card para adicionar novo animal (sempre visível)
          _buildAddAnimalCard(),
        ],
      ),
    );
  }

  Widget _buildAnimalInfoCard() {
    return Card(
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
              children: [
                const Icon(Icons.pets, color: Color(0xFF6A1B9A), size: 24),
                const SizedBox(width: 12),
                Text(
                  _selectedAnimal!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Espécie',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _selectedAnimal!.species,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Idade',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _selectedAnimal!.ageInYears != null 
                            ? '${_selectedAnimal!.ageInYears} anos' 
                            : 'Não especificada',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedAnimal!.medicalConditions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Condições médicas:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAnimal!.medicalConditions.join(', '),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Botão para encontrar veterinários especializados
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementar navegação para lista de veterinários especializados
                  print('Buscar veterinários para ${_selectedAnimal!.species}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Encontrar veterinários especializados',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnimalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.pets,
              size: 64,
              color: Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gerir os seus animais',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione o perfil completo do seu animal para obter recomendações personalizadas de veterinários',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navegar para adicionar animal
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      side: const BorderSide(color: Color(0xFF6A1B9A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Animal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navegar para gerir animais
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.list),
                    label: const Text('Ver Todos'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum veterinário encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
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

  void _onCallVeterinarian(Veterinarian vet) {
    print('A chamar: ${vet.phone}');
  }

  void _onChatVeterinarian(Veterinarian vet) {
    print('Iniciar chat com: ${vet.name}');
  }

  void _onBookAppointment(Veterinarian vet) {
    print('Marcar consulta com: ${vet.name}');
  }
}