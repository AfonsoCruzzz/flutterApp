import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../models/service_provider.dart';
import '../providers/user_provider.dart';

// Ecrãs e Widgets
import 'edit_profile_screen.dart';
// import 'pet_sitting_screen.dart'; // <--- Importa o teu ecrã de pesquisa aqui
import '../widgets/pet_sitter_card.dart'; // O Cartão que acabámos de editar
import '../widgets/profile_views/provider_profile_view.dart';
import '../widgets/profile_views/veterinarian_profile_view.dart'; // A nova view de vet

class ProfileScreen extends StatefulWidget {
  final bool isMyProfile;
  final String? userId;
  
  // --- NOVOS PARÂMETROS ---
  // Aceitamos o objeto já carregado para ser mais rápido (Preview)
  final Veterinarian? veterinarian; 
  final ServiceProvider? provider;

  const ProfileScreen({
    super.key, 
    this.isMyProfile = true, 
    this.userId,
    this.veterinarian, // Adiciona isto
    this.provider,     // Adiciona isto
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  User? _user;
  Veterinarian? _veterinarian;
  ServiceProvider? _provider;

  @override
  void initState() {
    super.initState();
    
    // 1. Aproveitar dados passados (Cache/Preview)
    if (widget.veterinarian != null) {
      _veterinarian = widget.veterinarian;
    }
    if (widget.provider != null) {
      _provider = widget.provider;
    }
    
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Definir qual o ID a procurar
    String? uid = widget.userId;
    
    if (widget.isMyProfile) {
      uid = context.read<UserProvider>().currentUser?.id;
    } else {
      uid ??= widget.veterinarian?.id ?? widget.provider?.id;
    }

    if (uid == null) return;

    try {
      // 1. Fetch User Base (Sempre necessário para o Cabeçalho: Nome/Foto)
      if (widget.isMyProfile) {
        _user = context.read<UserProvider>().currentUser;
      } else {
        // Se já tivermos o vet, às vezes o objeto Vet já tem nome/foto, 
        // mas o ProfileScreen espera um objeto 'User' separado. Vamos buscar para garantir.
        final uData = await _supabase.from('profiles').select().eq('id', uid).single();
        _user = User.fromMap(uData);
      }

      // 2. Fetch Veterinarian (Só se não foi passado por parâmetro)
      if (_user!.type == UserType.veterinarian && _veterinarian == null) {
        final vData = await _supabase.from('veterinarians').select().eq('id', uid).maybeSingle();
        if (vData != null) _veterinarian = Veterinarian.fromMap(vData);
      }

      // 3. Fetch Provider (Só se não foi passado por parâmetro)
      if (_user!.type == UserType.serviceProvider && _provider == null) {
        final pData = await _supabase.from('providers').select().eq('id', uid).maybeSingle();
        if (pData != null) _provider = ServiceProvider.fromMap(pData);
      }
      
    } catch (e) {
      print("Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Função para ligar/desligar visibilidade
  Future<void> _toggleProviderStatus(bool value) async {
    if (_provider == null) return;
    try {
      await _supabase.from('providers').update({'is_active': value}).eq('id', _user!.id);
      // Atualiza localmente
      setState(() {
         // Recriamos o objeto provider com o novo status (Models devem ser imutáveis idealmente)
         // Aqui faço um "hack" rápido recarregando tudo, ou podes criar método copyWith
         _loadProfileData();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? "Está visível para os clientes!" : "O seu perfil está oculto."),
        backgroundColor: value ? Colors.green : Colors.grey,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar estado.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text("Utilizador não encontrado")));

    final bool hasVetProfile = _veterinarian != null;
    final bool hasProviderProfile = _provider != null;
    final Color primaryPurple = const Color(0xFF6A1B9A);

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // Lógica das Abas
    if (hasVetProfile) {
      tabs.add(const Tab(text: "Veterinário", icon: Icon(Icons.medical_services)));
      tabViews.add(VeterinarianProfileView(veterinarian: _veterinarian!));
    }
    if (hasProviderProfile) {
      tabs.add(const Tab(text: "Serviços Pet", icon: Icon(Icons.pets)));
      tabViews.add(ProviderProfileView(provider: _provider!));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Perfil"),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            if (widget.isMyProfile)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6A1B9A)),
                onPressed: () async {
                  // 1. O 'await' é crucial! Ele obriga a esperar que voltes do outro ecrã
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        veterinarian: _veterinarian,
                        provider: _provider,
                      ),
                    ),
                  );
                  
                  // 2. Assim que o 'await' termina (tu voltas), esta função corre e atualiza o ecrã
                  // Se não tiveres isto, ele mostra os dados antigos
                  _loadProfileData(); 
                },
              )
          ],
        ),
        body: SingleChildScrollView( // Permite scroll em tudo
          child: Column(
            children: [
              // --- 1. HEADER (Igual) ---
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _user!.photo != null ? NetworkImage(_user!.photo!) : null,
                  child: _user!.photo == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(_user!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (_user!.city != null)
                Text("${_user!.city}, ${_user!.district}", style: const TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 20),

              // --- 2. CONTROLO DE PRESTADOR (Só se for o meu perfil e for provider) ---
              if (widget.isMyProfile && hasProviderProfile) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _provider!.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _provider!.isActive ? Colors.green : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: _provider!.isActive ? Colors.green : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_provider!.isActive ? "Estás Visível" : "Estás Oculto", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_provider!.isActive ? "Os clientes podem encontrar-te." : "Ativa para receber pedidos.",
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _provider!.isActive, 
                        activeColor: Colors.green,
                        onChanged: _toggleProviderStatus
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- 3. PRÉ-VISUALIZAÇÃO DO CARTÃO ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Como os clientes te veem:", style: TextStyle(color: Colors.grey, fontSize: 12))
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PetSitterCard(
                    user: _user!,
                    provider: _provider!,
                    onTap: () {
                      // Nada acontece na preview, ou podes abrir os detalhes
                    },
                  ),
                ),
                
                // Botão para ir para o ecrã de serviços (Pesquisa)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: OutlinedButton.icon(
                    onPressed: () {
                       // Navegar para o ecrã de lista de sitters
                       // Navigator.push(context, MaterialPageRoute(builder: (_) => const PetSittingScreen()));
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A abrir lista de serviços...")));
                    },
                    icon: const Icon(Icons.search),
                    label: const Text("Ver todos os Prestadores na minha zona"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      side: BorderSide(color: primaryPurple),
                      minimumSize: const Size(double.infinity, 45)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- 4. TABS E DETALHES ---
              if (tabs.isNotEmpty) ...[
                TabBar(
                  labelColor: primaryPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryPurple,
                  tabs: tabs,
                ),
                // Como estamos dentro de um SingleScrollView, o TabBarView precisa de altura fixa ou shrinkWrap
                // A melhor solução aqui é não usar Expanded, mas sim deixar o conteúdo fluir.
                // Truque: Usar um Builder para calcular altura ou usar um Container com altura fixa não é ideal.
                // Solução simples: Renderizar o widget da tab selecionada manualmente ou usar um Container grande.
                // Para manter simples e funcional com scroll, vou usar um Container com altura ajustada:
                SizedBox(
                  height: 600, // Altura estimada para o conteúdo das tabs
                  child: TabBarView(children: tabViews),
                ),
              ] else ...[
                 const Padding(
                   padding: EdgeInsets.all(40.0),
                   child: Text("Perfil de Cliente (Sem serviços ativos)", style: TextStyle(color: Colors.grey)),
                 )
              ],
            ],
          ),
        ),
      ),
    );
  }
}