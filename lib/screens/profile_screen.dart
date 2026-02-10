import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../models/service_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';

import 'edit_profile_screen.dart';
import '../widgets/profile_views/provider_profile_view.dart';
import '../widgets/profile_views/veterinarian_profile_view.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMyProfile;
  final String? userId;
  final Veterinarian? veterinarian;
  final ServiceProvider? provider;

  const ProfileScreen({
    super.key,
    this.isMyProfile = true,
    this.userId,
    this.veterinarian,
    this.provider,
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
    if (widget.veterinarian != null) _veterinarian = widget.veterinarian;
    if (widget.provider != null) _provider = widget.provider;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    String? uid = widget.userId;
    if (widget.isMyProfile) {
      uid = context.read<UserProvider>().currentUser?.id;
    } else {
      uid ??= widget.veterinarian?.id ?? widget.provider?.id;
    }

    if (uid == null) return;

    try {
      if (widget.isMyProfile) {
        _user = context.read<UserProvider>().currentUser;
      } else {
        final uData = await _supabase.from('profiles').select().eq('id', uid).single();
        _user = User.fromMap(uData);
      }

      if (_user!.type == UserType.veterinarian && _veterinarian == null) {
        final vData = await _supabase.from('veterinarians').select().eq('id', uid).maybeSingle();
        if (vData != null) _veterinarian = Veterinarian.fromMap(vData);
      }

      if (_user!.type == UserType.serviceProvider && _provider == null) {
        final pData = await _supabase.from('providers').select().eq('id', uid).maybeSingle();
        if (pData != null) _provider = ServiceProvider.fromMap(pData);
      }
    } catch (e) {
      debugPrint("Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleProviderStatus(bool value) async {
    if (_provider == null) return;
    setState(() {
      _provider = _provider!.copyWith(isActive: value);
    });
    try {
      await _supabase.from('providers').update({'is_active': value}).eq('id', _user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? "Visível para clientes!" : "Perfil oculto."),
          backgroundColor: value ? Colors.green : Colors.grey,
          duration: const Duration(milliseconds: 500),
        ));
      }
    } catch (e) {
      setState(() {
        _provider = _provider!.copyWith(isActive: !value);
      });
    }
  }

  Future<void> _toggleVetStatus(bool value) async {
    if (_veterinarian == null) return;
    setState(() {
      _veterinarian = _veterinarian!.copyWith(isActive: value);
    });
    try {
      await _supabase.from('veterinarians').update({'is_active': value}).eq('id', _user!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? "Visível" : "Oculto"),
          duration: const Duration(milliseconds: 500),
          backgroundColor: value ? Colors.green : Colors.grey,
        ));
      }
    } catch (e) {
      setState(() {
        _veterinarian = _veterinarian!.copyWith(isActive: !value);
      });
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

    if (hasVetProfile) {
      tabs.add(const Tab(text: "Veterinário", icon: Icon(Icons.medical_services)));
      // IMPORTANTE: As views internas (VeterinarianProfileView) já têm SingleChildScrollView.
      // O NestedScrollView vai gerir isso automaticamente.
      tabViews.add(VeterinarianProfileView(veterinarian: _veterinarian!, userBase: _user));
    }
    if (hasProviderProfile) {
      tabs.add(const Tab(text: "Serviços Pet", icon: Icon(Icons.pets)));
      tabViews.add(ProviderProfileView(provider: _provider!));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        // Removemos o AppBar daqui e passamos para dentro do NestedScrollView se quisermos que ele esconda,
        // ou mantemos aqui se quisermos que fique sempre fixo. Vou manter aqui para simplicidade,
        // mas o corpo agora é NestedScrollView.
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
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        veterinarian: _veterinarian,
                        provider: _provider,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _veterinarian = null;
                      _provider = null;
                      _isLoading = true;
                    });
                    await _loadProfileData();
                  }
                },
              ),
            if (widget.isMyProfile)
              IconButton(
                icon: Icon(Icons.logout, color: primaryPurple),
                onPressed: () async {
                  // Lógica de logout (mantida igual)
                   try {
                    context.read<UserProvider>().clearUser();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  } catch (e) {
                     // ...
                  }
                },
              ),
          ],
        ),
        
        // --- AQUI ESTÁ A CORREÇÃO MÁGICA ---
        body: NestedScrollView(
          // O headerSliverBuilder contém tudo o que faz scroll ANTES das abas (Avatar, Switches)
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
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

                    // --- Switches de Veterinário ---
                    if (widget.isMyProfile && hasVetProfile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildVetSwitch(),
                      ),

                    // --- Switches de Provider ---
                    if (widget.isMyProfile && hasProviderProfile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildProviderSwitch(),
                      ),
                  ],
                ),
              ),
              
              // Isto faz com que a TabBar fique "colada" no topo quando fazes scroll
              if (tabs.isNotEmpty)
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: primaryPurple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryPurple,
                      tabs: tabs,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  pinned: true,
                ),
            ];
          },
          // O corpo é APENAS o TabBarView. Não precisa de SizedBox(height: 600)!
          // Ele vai ocupar o espaço restante e fazer scroll em conjunto com o header.
          body: tabs.isNotEmpty 
            ? TabBarView(children: tabViews)
            : const Center(child: Text("Sem serviços ativos")),
        ),
      ),
    );
  }

  // Extraí os widgets dos switches para limpar o código do build
  Widget _buildVetSwitch() {
    return Container(
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
                Text(_veterinarian!.isActive ? "Aparece na pesquisa." : "Ative para receber marcações.",
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _veterinarian!.isActive,
            activeColor: const Color(0xFF6A1B9A),
            onChanged: (val) => _toggleVetStatus(val),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSwitch() {
    return Container(
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
            onChanged: _toggleProviderStatus,
          ),
        ],
      ),
    );
  }
}

// --- CLASSE AUXILIAR OBRIGATÓRIA PARA O TABBAR FICAR FIXO ---
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Fundo branco para a TabBar não ficar transparente
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}