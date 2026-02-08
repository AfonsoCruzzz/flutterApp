import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../models/service_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';

// Ecrãs e Widgets
import 'edit_profile_screen.dart';
// import 'pet_sitting_screen.dart'; // <--- Importa o teu ecrã de pesquisa aqui
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

    // 1. Atualização Visual Imediata (Optimistic Update)
    setState(() {
      _provider = _provider!.copyWith(isActive: value);
    });

    try {
      // 2. Enviar para a BD em background
      await _supabase.from('providers').update({'is_active': value}).eq('id', _user!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? "Visível para clientes!" : "Perfil oculto."),
          backgroundColor: value ? Colors.green : Colors.grey,
          duration: const Duration(milliseconds: 500),
        ));
      }
    } catch (e) {
      // 3. Reverter em caso de erro
      setState(() {
        _provider = _provider!.copyWith(isActive: !value);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar.")));
    }
  }

  // Função para ligar/desligar visibilidade do VETERINÁRIO
  Future<void> _toggleVetStatus(bool value) async {
    if (_veterinarian == null) return;

    // 1. ATUALIZAÇÃO VISUAL INSTANTÂNEA
    // Usamos o copyWith para mudar APENAS o isActive. 
    // O setState força o Flutter a redesenhar o switch imediatamente.
    setState(() {
      _veterinarian = _veterinarian!.copyWith(isActive: value);
    });

    try {
      // 2. Enviar para a Base de Dados em segundo plano
      await _supabase.from('veterinarians').update({'is_active': value}).eq('id', _user!.id);
      
      // (Opcional) Feedback visual rápido
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? "Visível" : "Oculto"), 
          duration: const Duration(milliseconds: 500),
          backgroundColor: value ? Colors.green : Colors.grey,
        ));
      }
    } catch (e) {
      // 3. Reverter em caso de erro (Voltamos a negar o valor)
      setState(() {
        _veterinarian = _veterinarian!.copyWith(isActive: !value);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro de conexão.")));
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
              // Dentro do build -> AppBar -> actions
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6A1B9A)),
                onPressed: () async {
                  // 1. Guardamos o resultado da navegação
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        veterinarian: _veterinarian,
                        provider: _provider,
                      ),
                    ),
                  );
                  
                  // 2. Se result for true, significa que o utilizador clicou em "Guardar"
                  if (result == true) {
                    setState(() {
                      // TRUQUE: Anulamos os objetos atuais para forçar o _loadProfileData
                      // a ir buscar tudo novo à base de dados
                      _veterinarian = null; 
                      _provider = null;
                      _isLoading = true; // Mostra o loading para dar feedback visual
                    });
                    
                    // 3. Agora sim, carregamos os dados frescos
                    await _loadProfileData();
                  }
                }
              ),
            if (widget.isMyProfile)
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
        body: SingleChildScrollView( // Permite scroll em tudo
        padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // --- 1. HEADER (Igual) ---
              const SizedBox(height: 15),
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
              
              const SizedBox(height: 15),

              if (widget.isMyProfile && hasVetProfile) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _veterinarian!.isActive ? Colors.purple.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _veterinarian!.isActive ? const Color(0xFF6A1B9A) : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital, color: _veterinarian!.isActive ? const Color(0xFF6A1B9A) : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_veterinarian!.isActive ? "Perfil Ativo" : "Perfil Oculto", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_veterinarian!.isActive ? "Aparece na pesquisa de médicos." : "Ative para receber marcações.",
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _veterinarian!.isActive, 
                        activeColor: const Color(0xFF6A1B9A),
                        onChanged: (val) => _toggleVetStatus(val), // Chama a nova função
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- 2. CONTROLO DE PRESTADOR (Só se for o meu perfil e for provider) ---
              // --- 2. CONTROLO DE PRESTADOR ---
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
                        onChanged: _toggleProviderStatus // Agora usa a versão rápida
                      ),
                    ],
                  ),
                ),
                
                // Removi o PetSitterCard e o texto "Como os clientes te veem" aqui.
                
                
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