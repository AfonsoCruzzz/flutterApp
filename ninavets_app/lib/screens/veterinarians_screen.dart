import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../models/veterinarian.dart';
import '../services/animal_service.dart';
import '../services/veterinarian_service.dart';
import '../widgets/veterinarian_card.dart';
import '../widgets/filter_section.dart';

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

  void _applyFilters() {
    List<Veterinarian> filtered = _allVeterinarians;

    // Filtrar por espécie (se na aba "Para o meu animal")
    if (_tabController.index == 0 && _selectedAnimal != null) {
      filtered = filtered.where((vet) => 
          vet.species.contains(_selectedAnimal!.species)).toList();
    }

    // Converter explicitamente para List<String> antes de usar
    final List<String> selectedSpecies = List<String>.from(_activeFilters['species'] ?? []);
    final List<String> selectedSpecialties = List<String>.from(_activeFilters['specialties'] ?? []);
    final List<String> selectedServices = List<String>.from(_activeFilters['services'] ?? []);

    // Filtrar por espécies selecionadas (aba "Necessidade específica")
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

  void _updateFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
    _applyFilters();
  }

  void _onAnimalSelected(Animal? animal) {
    setState(() {
      _selectedAnimal = animal;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamar Veterinário'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6A1B9A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6B35),
          tabs: const [
            Tab(text: 'Para o meu animal'),
            Tab(text: 'Para uma necessidade específica'),
          ],
          onTap: (index) {
            setState(() {});
            _applyFilters();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildForMyAnimalTab(),
                _buildForSpecificNeedTab(),
              ],
            ),
    );
  }

  Widget _buildForMyAnimalTab() {
    return Column(
      children: [
        // Seção de seleção de animal
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _userAnimals.isEmpty
              ? _buildAddAnimalButton()
              : _buildAnimalDropdown(),
        ),
        // Lista de veterinários
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

  Widget _buildForSpecificNeedTab() {
    return Column(
      children: [
        // Filtros (sempre visíveis no topo em mobile)
        if (MediaQuery.of(context).size.width <= 600)
          Container(
            height: MediaQuery.of(context).size.height * 0.6, // 60% da altura
            child: FilterSection(
              filters: _activeFilters,
              onFiltersChanged: _updateFilters,
            ),
          ),
        
        // Conteúdo principal
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar com filtros (apenas em desktop)
              if (MediaQuery.of(context).size.width > 600)
                Container(
                  width: 320, // Largura fixa para sidebar
                  child: FilterSection(
                    filters: _activeFilters,
                    onFiltersChanged: _updateFilters,
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
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione o seu animal:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Animal>(
          value: _selectedAnimal,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: _userAnimals.map((Animal animal) {
            return DropdownMenuItem<Animal>(
              value: animal,
              child: Row(
                children: [
                  const Icon(Icons.pets, color: Color(0xFF6A1B9A)),
                  const SizedBox(width: 8),
                  Text(animal.name),
                  const SizedBox(width: 8),
                  Text(
                    '(${animal.species})',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _onAnimalSelected,
        ),
      ],
    );
  }

  Widget _buildAddAnimalButton() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.pets,
              size: 64,
              color: Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum animal encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione o perfil do seu animal para encontrar veterinários especializados',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navegar para ecrã de adicionar animal
                // Navigator.push(context, MaterialPageRoute(builder: (context) => AddAnimalScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Adicionar Animal',
                style: TextStyle(color: Colors.white),
              ),
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
            onPressed: () {
              setState(() {
                _activeFilters = {
                  'species': [],
                  'specialties': [],
                  'services': [],
                  'location': {'postalCode': '', 'distance': 25},
                  'availability': {'openNow': false, 'emergency24h': false},
                };
              });
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: const Text('Limpar Filtros'),
          ),
        ],
      ),
    );
  }

  void _onCallVeterinarian(Veterinarian vet) {
    // TODO: Implementar chamada telefónica
    print('A chamar: ${vet.phone}');
  }

  void _onChatVeterinarian(Veterinarian vet) {
    // TODO: Implementar chat
    print('Iniciar chat com: ${vet.name}');
  }

  void _onBookAppointment(Veterinarian vet) {
    // TODO: Implementar marcação de consulta
    print('Marcar consulta com: ${vet.name}');
  }
}