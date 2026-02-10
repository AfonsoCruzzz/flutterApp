import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User; // Esconder User do Supabase para usar o nosso
import '../models/user.dart';
import '../models/service_provider.dart';
import '../widgets/pet_sitter_card.dart'; // O novo cartão
import 'profile_screen.dart'; // Para navegar para o perfil
import './pet_sitting_search_screen.dart'; // O teu ecrã de filtros
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

class PetSittingScreen extends StatefulWidget {
  const PetSittingScreen({super.key});

  @override
  State<PetSittingScreen> createState() => _PetSittingScreenState();
}

class _PetSittingScreenState extends State<PetSittingScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Lista de Pares (User + Provider)
  List<Map<String, dynamic>> _loadedProviders = [];

  // Filtros ativos
  Map<String, dynamic> _activeFilters = {
    'searchQuery': '',
    'species': <String>[],
    'services': <String>[],
    'maxPrice': 100.0,
  };

  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  // 1. BUSCAR DADOS AO SUPABASE
  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      // Seleciona todos os providers ATIVOS e junta com a tabela profiles
      // A sintaxe '*, profiles(*)' faz um "JOIN" automático se houver chave estrangeira (id)
      final response = await _supabase
          .from('providers')
          .select('*, profiles(*)')
          .eq('is_active', true);

      final List<dynamic> data = response;
      
      List<Map<String, dynamic>> tempScrollList = [];

      for (var item in data) {
        // O Supabase retorna o profile dentro de uma chave 'profiles' (pode ser lista ou objeto)
        // Geralmente é um objeto se for relação 1:1
        final profileData = item['profiles']; 
        
        if (profileData != null) {
          // Criar os nossos modelos
          final provider = ServiceProvider.fromMap(item);
          final user = User.fromMap(profileData);

          tempScrollList.add({
            'user': user,
            'provider': provider,
          });
        }
      }

      setState(() {
        _loadedProviders = tempScrollList;
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao buscar providers: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar lista: $e')),
        );
      }
    }
  }

  // 2. FILTRAGEM LOCAL (CLIENT-SIDE)
  List<Map<String, dynamic>> get _filteredList {
    return _loadedProviders.where((item) {
      final User user = item['user'];
      final ServiceProvider provider = item['provider'];

      // Filtro por Texto (Nome ou Cidade)
      final String query = _activeFilters['searchQuery'].toLowerCase();
      final bool matchesSearch = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          (user.city != null && user.city!.toLowerCase().contains(query)) ||
          (user.district != null && user.district!.toLowerCase().contains(query));

      // Filtro por Espécies (Animais Aceites)
      final List<String> filterSpecies = List<String>.from(_activeFilters['species'] ?? []);
      final bool matchesSpecies = filterSpecies.isEmpty ||
          filterSpecies.any((s) => provider.acceptedPets.contains(s));

      // Filtro por Serviços
      final List<String> filterServices = List<String>.from(_activeFilters['services'] ?? []);
      final bool matchesServices = filterServices.isEmpty ||
          filterServices.any((s) => provider.serviceTypes.contains(s));

      // Filtro por Preço Máximo
      // Verifica se o provider tem ALGUM serviço abaixo do preço máximo
      double minProviderPrice = 9999.0;
      if (provider.prices.isNotEmpty) {
        minProviderPrice = provider.prices.values.reduce((curr, next) => curr < next ? curr : next);
      }
      final bool matchesPrice = minProviderPrice <= (_activeFilters['maxPrice'] ?? 100.0);

      return matchesSearch && matchesSpecies && matchesServices && matchesPrice;
    }).toList();
  }

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
    final filtered = _filteredList;

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
            icon: const Icon(Icons.filter_list),
            color: primaryPurple,
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumo dos Filtros
          if (_hasActiveFilters())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getActiveFiltersSummary(),
                      style: TextStyle(color: primaryPurple, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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
                    child: Text('Limpar', style: TextStyle(color: primaryOrange)),
                  ),
                ],
              ),
            ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} prestadores encontrados',
                  style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // Lista de Cards
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryOrange))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final User u = item['user'];
                        final ServiceProvider p = item['provider'];

                        return PetSitterCard(
                          user: u,
                          provider: p,
                          onTap: () {
                            // Navegar para o Perfil do Prestador
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  isMyProfile: false,
                                  userId: u.id,
                                  provider: p, // Passamos o objeto para abrir rápido
                                ),
                              ),
                            );
                          },
                          onChat: () => _openChat(u),
                          onBook: () {
    // Obter o utilizador atual (Cliente)
                            final currentUser = context.read<UserProvider>().currentUser;
                            
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Precisa de fazer login.")));
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(
                                  provider: p,         // O prestador do card
                                  client: currentUser, // Eu, o cliente
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      // BottomNavigationBar REMOVIDA
    );
  }

  Future<void> _openChat(User targetUser) async {
  final currentUser = context.read<UserProvider>().currentUser;
  
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faça login para enviar mensagens.")));
    return;
  }

  try {
    final myId = currentUser.id;
    final otherId = targetUser.id;

    // 1. Procura se já existe conversa
    // CORREÇÃO AQUI: Mudámos de user1_id/user2_id para user_a/user_b
    final data = await _supabase
        .from('conversations')
        .select()
        .or('and(user_a.eq.$myId,user_b.eq.$otherId),and(user_a.eq.$otherId,user_b.eq.$myId)')
        .maybeSingle();

    String conversationId;

    if (data != null) {
      // Já existe
      conversationId = data['id'];
    } else {
      // Não existe, criar nova
      // CORREÇÃO AQUI TAMBÉM: Ao inserir, usar user_a e user_b
      final newConv = await _supabase.from('conversations').insert({
        'user_a': myId,
        'user_b': otherId,
        'updated_at': DateTime.now().toIso8601String(),
        // Podes adicionar 'last_message': '' se a tua tabela tiver essa coluna e for obrigatória
      }).select().single();
      
      conversationId = newConv['id'];
    }

    // 2. Abrir o ChatScreen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserId: targetUser.id,
            otherUserName: targetUser.name,
            otherUserPhoto: targetUser.photo,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao abrir chat: $e")));
  }
}


  // --- HELPERS ---

  bool _hasActiveFilters() {
    return _activeFilters['searchQuery'].isNotEmpty ||
        (_activeFilters['species'] as List).isNotEmpty ||
        (_activeFilters['services'] as List).isNotEmpty ||
        _activeFilters['maxPrice'] != 100.0;
  }

  String _getActiveFiltersSummary() {
    List<String> active = [];
    if (_activeFilters['searchQuery'].isNotEmpty) {
      active.add('"${_activeFilters['searchQuery']}"');
    }
    if ((_activeFilters['species'] as List).isNotEmpty) {
      active.add('${(_activeFilters['species'] as List).length} espécies');
    }
    if ((_activeFilters['services'] as List).isNotEmpty) {
      active.add('${(_activeFilters['services'] as List).length} serviços');
    }
    if (_activeFilters['maxPrice'] != 100.0) {
      active.add('Até ${_activeFilters['maxPrice'].round()}€');
    }
    return 'Filtros: ${active.join(' • ')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum prestador encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Tente ajustar os filtros', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _openFilterScreen,
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            child: const Text('Abrir Filtros'),
          ),
        ],
      ),
    );
  }
}