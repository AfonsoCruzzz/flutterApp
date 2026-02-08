import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- IMPORTANTE: Provider
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens e Widgets
import './veterinarians_filter_screen.dart';
import 'add_animal_screen.dart'; // O ecrã de formulário que criámos antes
import '../widgets/veterinarian_card.dart';
import '../widgets/animal_card.dart'; // O novo widget reutilizável

// Providers e Models
import '../providers/animal_provider.dart'; // <--- O teu novo Provider
import '../providers/user_provider.dart';   // Para obter o user ID atual
import '../models/animal.dart';
import '../models/veterinarian.dart';
import '../services/veterinarian_service.dart';
import 'profile_screen.dart';

class VeterinariansScreen extends StatefulWidget {
  const VeterinariansScreen({super.key});

  @override
  State<VeterinariansScreen> createState() => _VeterinariansScreenState();
}

class _VeterinariansScreenState extends State<VeterinariansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Dados dos Veterinários (Mantemos local pois é específico deste ecrã de pesquisa)
  List<Veterinarian> _allVeterinarians = [];
  List<Veterinarian> _filteredVeterinarians = [];
  bool _isLoadingVets = true;
  
  // Filtros ativos
  Map<String, dynamic> _activeFilters = {
    'species': <String>[],
    'specialties': <String>[],
    'services': <String>[],
    'location': {'postalCode': '', 'distance': 25},
    'availability': {'openNow': false, 'emergency24h': false},
  };

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Carregar dados após o build inicial para ter acesso ao context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);

    // 1. Carregar Animais via Provider (Gestão de Estado Global)
    if (userProvider.currentUser != null) {
      // Não precisamos de 'await' aqui se quisermos que carregue em paralelo,
      // pois o Consumer vai atualizar a UI quando terminar.
      animalProvider.loadAnimals(userProvider.currentUser!.id);
    }

    // 2. Carregar Veterinários (Localmente, pois é dados de pesquisa)
    try {
      final veterinarians = await VeterinarianService.getAllVeterinarians();
      if (mounted) {
        setState(() {
          _allVeterinarians = veterinarians;
          _filteredVeterinarians = veterinarians;
          _isLoadingVets = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('Erro a carregar veterinários: $e');
      if (mounted) setState(() => _isLoadingVets = false);
    }
  }

  // --- Lógica de Filtros (Mantida igual para Tab 1) ---
  Future<void> _openFilterScreen() async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VeterinariansFilterScreen(initialFilters: _activeFilters),
      ),
    );

    if (result != null) {
      setState(() => _activeFilters = result);
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Veterinarian> filtered = _allVeterinarians;
    final List<String> selectedSpecies = List<String>.from(_activeFilters['species'] ?? []);
    // ... (Mantém a tua lógica de filtros aqui) ...
    // Simplificado para brevidade, mas o teu código original de _applyFilters entra aqui
    // Se a espécie estiver selecionada, filtra por ela:
    if (selectedSpecies.isNotEmpty) {
      filtered = filtered.where((vet) => 
          selectedSpecies.any((species) => vet.species.contains(species))).toList();
    }
    
    setState(() => _filteredVeterinarians = filtered);
  }

  // --- AÇÃO INTELIGENTE: Encontrar Vet para o Animal ---
  void _findVetsForAnimal(Animal animal) {
    // 1. Define o filtro para a espécie do animal
    setState(() {
      _activeFilters['species'] = [animal.species]; // Ex: ['Cão']
    });
    
    // 2. Aplica os filtros
    _applyFilters();

    // 3. Muda para a tab de pesquisa
    _tabController.animateTo(0);

    // 4. Feedback ao utilizador
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A mostrar veterinários para: ${animal.name} (${animal.species})'),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            Tab(text: 'Pesquisa Geral'), 
            Tab(text: 'Meus Animais'), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForSpecificNeedTab(), // Tab 1 (A tua lista de vets)
          _buildForMyAnimalTab(),     // Tab 2 (A nova lista limpa)
        ],
      ),
    );
  }

  // --- TAB 1: Pesquisa Geral (Mantido a estrutura, simplificado visualmente) ---
  Widget _buildForSpecificNeedTab() {
    if (_isLoadingVets) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Barra de topo com contagem e filtro
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_filteredVeterinarians.length} veterinários encontrados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryPurple),
                ),
              ),
              IconButton(
                onPressed: _openFilterScreen,
                icon: const Icon(Icons.filter_list),
                color: primaryPurple,
                tooltip: "Filtrar",
              ),
            ],
          ),
        ),
        
        // Lista de Vets
        Expanded(
          child: _filteredVeterinarians.isEmpty
              ? _buildEmptyVetState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredVeterinarians.length,
                  itemBuilder: (context, index) {
                    final vet = _filteredVeterinarians[index];
                    return VeterinarianCard(
                      veterinarian: vet,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              isMyProfile: false, // Importante: Esconde botões de editar
                              userId: vet.id, // Importante passar o ID para ele buscar o User base (foto/nome)
                              veterinarian: vet,
                            ),
                          ),
                        );
                      },
                      onCall: () {}, // Implementar lógica de chamada
                      onChat: () {}, // Implementar lógica de chat
                      onBook: () {}, // Implementar lógica de booking
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: Meus Animais (NOVA ESTRUTURA CLEAN) ---
  Widget _buildForMyAnimalTab() {
    // O Consumer ouve o AnimalProvider. Sempre que chamares notifyListeners() lá, isto redesenha.
    return Consumer<AnimalProvider>(
      builder: (context, animalProvider, child) {
        
        // 1. Loading State
        if (animalProvider.isLoading) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }

        final animals = animalProvider.myAnimals;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho com Botão "Novo"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Os seus companheiros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryPurple),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const AddAnimalScreen())
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                "Toque num animal para encontrar especialistas para ele.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 16),

              // 2. Empty State (Sem animais)
              if (animals.isEmpty) 
                _buildEmptyAnimalState(context)
              else 
                // 3. Lista de Animais (Usando o Widget AnimalCard)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: animals.length,
                  itemBuilder: (ctx, index) {
                    final animal = animals[index];
                    return AnimalCard(
                      animal: animal,
                      onTap: () => _findVetsForAnimal(animal), // <--- A Magia acontece aqui

                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAnimalScreen(animalToEdit: animal), // Passamos o animal!
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Estados Vazios (UI Helpers)
  Widget _buildEmptyVetState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Sem resultados com estes filtros.', style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () {
             setState(() {
                _activeFilters['species'] = <String>[];
                // Limpar outros filtros...
             });
             _applyFilters();
          },
          child: Text('Limpar Filtros', style: TextStyle(color: primaryOrange)),
        )
      ],
    );
  }

  Widget _buildEmptyAnimalState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pets, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Ainda não adicionou nenhum animal.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAnimalScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryPurple,
                side: BorderSide(color: primaryPurple),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Criar Primeiro Perfil"),
            ),
          ),
        ],
      ),
    );
  }
}