import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart'; // Para usar o UserType enum se precisares

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('verification_status', 'pending'); // Só traz os pendentes
      
      setState(() {
        _pendingRequests = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar pedidos: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String userId, String requestedRole, Map<String, dynamic> profileData) async {
    try {
      // 1. TRADUÇÃO: Garantir que o nome corresponde ao que a Base de Dados espera
      String dbRoleName = requestedRole;
      
      if (requestedRole == 'serviceProvider') {
        dbRoleName = 'provider'; // <--- A CORREÇÃO MÁGICA
      }
      // (Os outros, 'veterinarian' e 'student', geralmente são iguais, mas confirma se 'student' na BD é 'student')

      // 2. Atualizar o Perfil com o nome correto
      await _supabase.from('profiles').update({
        'role': dbRoleName, // Usa o nome corrigido ('provider')
        'pending_role': null,
        'verification_status': 'approved',
      }).eq('id', userId);

      // 3. Criar entrada na tabela específica
      // Nota: Aqui usamos a variável original 'requestedRole' ou a 'dbRoleName' para a lógica do if,
      // mas o insert na tabela 'providers' não muda.
      
      if (dbRoleName == 'veterinarian') {
        final exists = await _supabase.from('veterinarians').select().eq('id', userId).maybeSingle();
        if (exists == null) {
           await _supabase.from('veterinarians').insert({
             'id': userId, 
             'license_number': profileData['license_number'] ?? 'Pendente',
             'is_verified': true
           });
        }
      } else if (dbRoleName == 'provider') { // <--- Ajustado para validar pelo nome da BD
        final exists = await _supabase.from('providers').select().eq('id', userId).maybeSingle();
        if (exists == null) {
           await _supabase.from('providers').insert({'id': userId});
        }
      } else if (dbRoleName == 'student') {
        final exists = await _supabase.from('students').select().eq('id', userId).maybeSingle();
        if (exists == null) {
           await _supabase.from('students').insert({
             'id': userId,
             'student_number': 'Pendente',
           });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aprovado com sucesso!")));
      _fetchPendingRequests(); // Atualiza a lista

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  Future<void> _rejectUser(String userId) async {
    await _supabase.from('profiles').update({
      'verification_status': 'rejected',
      'pending_role': null,
    }).eq('id', userId);
    _fetchPendingRequests();
  }
  
  // Função auxiliar para ver a imagem (Opcional - requer lógica de download assinada)
  // Por agora simplificamos.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Painel de Administrador")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _pendingRequests.isEmpty 
            ? const Center(child: Text("Não há pedidos pendentes."))
            : ListView.builder(
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final req = _pendingRequests[index];
                  final name = req['full_name'] ?? 'Sem nome';
                  final wantedRole = req['pending_role'] ?? 'Desconhecido';
                  
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(name),
                          subtitle: Text("Quer ser: $wantedRole"),
                          leading: const Icon(Icons.person_search),
                        ),
                        // Aqui podias meter um botão "Ver Documento"
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _rejectUser(req['id']),
                                child: const Text("Rejeitar", style: TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _approveUser(req['id'], wantedRole, req),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text("Aprovar", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
    );
  }
}