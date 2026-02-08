import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/user.dart'; // Para verificar o UserType
import '../models/animal.dart';     // <--- IMPORTANTE
import '../widgets/animal_card.dart'; // <--- IMPORTANTE
import 'animal_detail_screen.dart';   // <--- IMPORTANTE

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final bool isProviderView; // Para saber se mostramos botões de prestador ou cliente

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.isProviderView,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoadingAnimals = true;
  List<Animal> _animals = [];
  bool _isActionLoading = false;

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _fetchBookingAnimals();
  }

  // Buscar quais animais estão nesta reserva
  Future<void> _fetchBookingAnimals() async {
    try {
      final response = await _supabase
          .from('booking_animals')
          .select('animals(*)') 
          .eq('booking_id', widget.booking['id']);

      if (mounted) {
        setState(() {
          // Converter a resposta JSON diretamente para objetos Animal
          final List<dynamic> data = response;
          _animals = data.map((item) => Animal.fromMap(item['animals'])).toList();
          _isLoadingAnimals = false;
        });
      }
    } catch (e) {
      print("Erro animais: $e");
      if (mounted) setState(() => _isLoadingAnimals = false);
    }
  }

  // Verificar se a data do serviço é HOJE
  bool _isToday() {
    final dates = widget.booking['scheduled_dates'] as List?;
    if (dates == null || dates.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    return dates.any((d) => d.toString().startsWith(todayStr));
  }

  // Atualizar Estado (Aceitar, Recusar, Iniciar, Terminar)
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActionLoading = true);
    try {
      await _supabase.from('bookings').update({'status': newStatus}).eq('id', widget.booking['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Estado atualizado!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar."), backgroundColor: Colors.red));
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.booking['status'];
    final profile = widget.isProviderView ? widget.booking['client'] : widget.booking['provider'];
    final String name = profile?['full_name'] ?? 'Utilizador';
    final String? photo = profile?['photo'];
    
    // Formatar Datas
    final datesList = (widget.booking['scheduled_dates'] as List?) ?? [];
    String dateText = "Data a definir";
    if (datesList.isNotEmpty) {
      // Exemplo: 10 Fev, 11 Fev...
      dateText = datesList.map((d) => DateFormat('dd MMM').format(DateTime.parse(d.toString()))).join(", ");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes do Serviço"),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CABEÇALHO (Quem é o Cliente/Prestador?)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    backgroundColor: primaryPurple.withOpacity(0.1),
                    child: photo == null ? Icon(Icons.person, size: 40, color: primaryPurple) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    widget.isProviderView ? "Cliente" : "Prestador",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. CARD DE INFORMAÇÕES
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.work, "Serviço", widget.booking['service_type'].toString().toUpperCase().replaceAll('_', ' ')),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.calendar_today, "Data(s)", dateText),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.euro, "Valor Total", "${widget.booking['total_price']}€"),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.info_outline, "Estado", status.toString().toUpperCase(), 
                    color: status == 'confirmed' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. ANIMAIS ENVOLVIDOS
            const Text("Animais", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            _isLoadingAnimals
                ? const Center(child: CircularProgressIndicator())
                : _animals.isEmpty 
                    ? const Text("Sem animais associados.")
                    : Column(
                        children: _animals.map((animal) => AnimalCard( // <--- USAMOS O TEU WIDGET!
                          animal: animal,
                          onTap: () {
                            // Navegar para o ecrã de detalhes completos
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnimalDetailScreen(animal: animal),
                              ),
                            );
                          },
                          // onEdit: null -> Não passamos onEdit aqui porque é histórico, não edição
                        )).toList(),
                      ),

            const SizedBox(height: 24),

            // 4. NOTAS DO CLIENTE
            if (widget.booking['client_notes'] != null && widget.booking['client_notes'].toString().isNotEmpty) ...[
              const Text("Notas do Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Text(widget.booking['client_notes']),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),

      // 5. BARRA DE AÇÕES (Onde a magia acontece)
      bottomNavigationBar: _buildBottomActions(status),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color ?? Colors.black87)),
          ],
        )
      ],
    );
  }

  Widget? _buildBottomActions(String status) {
    // Se estiver a carregar ação
    if (_isActionLoading) {
      return const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator());
    }

    // Se sou o Prestador
    if (widget.isProviderView) {
      if (status == 'pending') {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _updateStatus('declined'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.all(16)), child: const Text("Recusar"))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: () => _updateStatus('confirmed'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)), child: const Text("Aceitar", style: TextStyle(color: Colors.white)))),
            ],
          ),
        );
      }
      
      if (status == 'confirmed') {
        final isToday = _isToday();
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            // Só ativa se for HOJE
            onPressed: isToday ? () => _updateStatus('in_progress') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              isToday ? "INICIAR SERVIÇO" : "Aguarde pelo dia do serviço",
              style: TextStyle(color: isToday ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      if (status == 'in_progress') {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus('completed'), // Futuramente abre ecrã de relatório
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, padding: const EdgeInsets.all(16)),
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text("TERMINAR SERVIÇO", style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } 
    
    // Se sou Cliente (pode cancelar se ainda estiver pendente ou confirmado)
    else {
      if (status == 'pending' || status == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () => _updateStatus('cancelled'),
            child: const Text("Cancelar Reserva", style: TextStyle(color: Colors.red)),
          ),
        );
      }
    }

    return null;
  }
}