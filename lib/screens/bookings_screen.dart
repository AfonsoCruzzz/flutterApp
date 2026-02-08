import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  bool _isViewAsProvider = false; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Verificar se o user é provider por defeito para definir a view inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      if (user != null && (user.type == UserType.serviceProvider || user.type == UserType.veterinarian)) {
        setState(() => _isViewAsProvider = true);
      }
      _fetchBookings();
    });
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    try {
      // Se estou a ver como prestador, filtro onde EU sou o provider_id
      final column = _isViewAsProvider ? 'provider_id' : 'client_id';

      // Join: Se sou provider, quero ver quem é o cliente. Se sou cliente, quero ver quem é o provider.
      final response = await _supabase
          .from('bookings')
          .select('*, profiles!client_id(full_name, photo), providers!provider_id(description, id)') 
          .eq(column, user.id)
          .order('created_at', ascending: false);
      
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Erro bookings: $e");
    }
  }

  // --- NOVA FUNÇÃO: ATUALIZAR ESTADO ---
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _supabase.from('bookings').update({'status': newStatus}).eq('id', bookingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'confirmed' ? "Reserva confirmada!" : "Reserva recusada."),
            backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          )
        );
        _fetchBookings(); // Recarregar a lista
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar.")));
    }
  }

  List<Map<String, dynamic>> _filterByStatus(List<String> statuses) {
    return _bookings.where((b) {
      final s = (b['status'] as String).toLowerCase();
      return statuses.contains(s);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final bool canBeProvider = user?.type == UserType.veterinarian || user?.type == UserType.serviceProvider;
    const Color primaryPurple = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestão de Reservas"),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
        actions: [
          if (canBeProvider)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isViewAsProvider = !_isViewAsProvider;
                  _fetchBookings();
                });
              },
              icon: Icon(_isViewAsProvider ? Icons.work : Icons.person, size: 18),
              label: Text(_isViewAsProvider ? "Modo Prestador" : "Modo Cliente"),
              style: TextButton.styleFrom(foregroundColor: primaryPurple),
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryPurple,
          tabs: const [
            Tab(text: "Pendentes"),
            Tab(text: "Aceites/Em Curso"),
            Tab(text: "Histórico"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              // 1. Pendentes (Aqui é que aparecem os botões de Aceitar/Recusar)
              _buildList(_filterByStatus(['pending']), showActions: true),
              
              // 2. Aceites e Em Curso
              _buildList(_filterByStatus(['confirmed', 'in_progress'])),
              
              // 3. Histórico
              _buildList(_filterByStatus(['completed', 'cancelled', 'declined'])),
            ],
          ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Sem reservas nesta categoria.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final booking = items[index];
        final status = booking['status'] ?? 'pending';
        final dates = booking['scheduled_dates'] as List?;
        final clientProfile = booking['profiles']; // Info do cliente (se sou provider)
        
        // Formatar Data
        String dateStr = "Sem data";
        if (dates != null && dates.isNotEmpty) {
           dateStr = DateFormat('dd MMM', 'pt_PT').format(DateTime.parse(dates[0].toString()));
           if (dates.length > 1) dateStr += " (+${dates.length - 1} dias)";
        }
        
        // Nome a mostrar (Se sou provider, mostro nome do cliente)
        String displayName = "Serviço";
        String? photoUrl;
        
        if (_isViewAsProvider && clientProfile != null) {
          displayName = clientProfile['full_name'] ?? 'Cliente';
          photoUrl = clientProfile['photo'];
        } else {
          // Se sou cliente, devia mostrar o nome do provider (requer join diferente ou extra logic)
          // Simplificação: Mostrar tipo de serviço
          displayName = _formatServiceType(booking['service_type']);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  child: photoUrl == null ? Icon(_getStatusIcon(status), color: _getStatusColor(status)) : null,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatServiceType(booking['service_type'])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateStr, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    if (booking['total_price'] != null && booking['total_price'] > 0)
                      Text("${booking['total_price']}€", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                trailing: _buildStatusChip(status),
              ),
              
              // --- ZONA DE AÇÕES (ACEITAR / RECUSAR) ---
              // Só mostramos se:
              // 1. Estivermos no modo Provider
              // 2. O estado for Pending
              // 3. A flag showActions for true
              if (showActions && _isViewAsProvider && status == 'pending')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateBookingStatus(booking['id'], 'declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text("Recusar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateBookingStatus(booking['id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Aceitar"),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPERS (Iguais) ---
  String _formatServiceType(String type) => type.replaceAll('_', ' ').toUpperCase(); 
  Color _getStatusColor(String status) {
    switch(status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': case 'declined': return Colors.red;
      default: return Colors.grey;
    }
  }
  IconData _getStatusIcon(String status) {
    switch(status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'completed': return Icons.task_alt;
      case 'cancelled': case 'declined': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }
  Widget _buildStatusChip(String status) {
    String label = status;
    switch(status) {
      case 'pending': label = 'Pendente'; break;
      case 'confirmed': label = 'Confirmado'; break;
      case 'in_progress': label = 'Em Curso'; break;
      case 'completed': label = 'Concluído'; break;
      case 'cancelled': label = 'Cancelado'; break;
      case 'declined': label = 'Recusado'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
    );
  }
}