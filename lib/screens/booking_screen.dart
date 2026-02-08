import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatar moeda e datas

import '../models/service_provider.dart';
import '../models/user.dart' as app_user; // Alias para evitar conflito com Supabase User
import '../models/animal.dart';
import '../models/working_schedule.dart';

class BookingScreen extends StatefulWidget {
  final ServiceProvider provider;
  final app_user.User client; // O utilizador logado

  const BookingScreen({
    super.key,
    required this.provider,
    required this.client,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _supabase = Supabase.instance.client;
  
  // Estado da Marcação
  String? _selectedService;
  List<String> _selectedPetIds = [];
  List<DateTime> _selectedDates = [];
  String _clientNotes = '';

  // Estado dos Dados
  bool _isLoadingPets = true;
  List<Animal> _myPets = [];
  
  // Calendário
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchClientPets();
  }

  // 1. Buscar animais do cliente
  Future<void> _fetchClientPets() async {
    try {
      final data = await _supabase
          .from('animals')
          .select()
          .eq('owner_id', widget.client.id);

      final List<Animal> loadedPets = (data as List)
          .map((item) => Animal.fromMap(item))
          .toList();

      setState(() {
        _myPets = loadedPets;
        _isLoadingPets = false;
      });
    } catch (e) {
      if(mounted) {
        setState(() => _isLoadingPets = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao carregar animais: $e")));
      }
    }
  }

  // 2. Lógica de Preço (Simples: Preço Base * Dias * Animais)
  double get _totalPrice {
    if (_selectedService == null || _selectedDates.isEmpty || _selectedPetIds.isEmpty) {
      return 0.0;
    }
    
    double basePrice = widget.provider.prices[_selectedService] ?? 0.0;
    int daysCount = _selectedDates.length;
    int petsCount = _selectedPetIds.length;

    // Lógica: Preço por dia * Dias * Animais 
    // (Podes ajustar se cobrares menos pelo 2º animal, mas vamos manter simples)
    return basePrice * daysCount * petsCount;
  }

  // 3. Submeter Marcação
  Future<void> _submitBooking() async {
    if (_selectedService == null) return _showError("Selecione um serviço.");
    if (_selectedPetIds.isEmpty) return _showError("Selecione pelo menos um animal.");
    if (_selectedDates.isEmpty) return _showError("Selecione os dias no calendário.");

    try {
      // Ordenar datas
      _selectedDates.sort();

      final bookingData = {
        'client_id': widget.client.id,
        'provider_id': widget.provider.id,
        'service_type': _selectedService,
        'status': 'pending',
        'total_price': _totalPrice,
        // Enviar array de datas para o Supabase (Postgres DATE[])
        'scheduled_dates': _selectedDates.map((d) => d.toIso8601String().split('T')[0]).toList(),
        'client_notes': _clientNotes,
      };

      // Inserir Booking Pai
      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      final String bookingId = response['id'];

      // Inserir Relação Booking-Animais (Tabela de Junção)
      // Assumindo que tens uma tabela 'booking_animals' (booking_id, animal_id)
      for (String petId in _selectedPetIds) {
        await _supabase.from('booking_animals').insert({
          'booking_id': bookingId,
          'animal_id': petId,
        });
      }

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pedido enviado com sucesso!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Voltar atrás
      }

    } catch (e) {
      _showError("Erro ao marcar: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    return Scaffold(
      appBar: AppBar(
        title: Text("Marcar com ${widget.client.name.split(' ')[0]}"), // Nome do Provider aqui seria melhor, mas o objeto Client é o User logado. 
        // Nota: Devias passar o nome do Provider no construtor também para exibir no título.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ESCOLHER SERVIÇO ---
            _buildSectionTitle("1. Qual o serviço?", primaryPurple),
            Wrap(
              spacing: 8,
              children: widget.provider.serviceTypes.map((serviceKey) {
                final isSelected = _selectedService == serviceKey;
                final price = widget.provider.prices[serviceKey] ?? 0;
                
                return ChoiceChip(
                  label: Text("${ServiceProvider.getServiceLabel(serviceKey)} (${price.toStringAsFixed(0)}€)"),
                  selected: isSelected,
                  selectedColor: primaryOrange.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? primaryOrange : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedService = selected ? serviceKey : null);
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),

            // --- 2. ESCOLHER ANIMAIS (Filtrados) ---
            _buildSectionTitle("2. Para quem é?", primaryPurple),
            if (_isLoadingPets) 
              const Center(child: CircularProgressIndicator())
            else if (_myPets.isEmpty)
              const Text("Não tem animais registados no seu perfil.")
            else
              Column(
                children: _myPets.map((pet) {
                  // FILTRO IMPORTANTE: O Provider aceita esta espécie?
                  // Assumindo que pet.species é "Cão" e provider.acceptedPets tem "Cães"
                  // Atenção à normalização de strings (singular/plural). 
                  // Para simplificar, vou verificar se a string está contida.
                  
                  // Normalização básica para demo:
                  // Se o provider tem "Cães", aceita "Cão". Se "Gatos", aceita "Gato".
                  bool isAccepted = widget.provider.acceptedPets.any((accepted) {
                    final a = accepted.toLowerCase(); // cães
                    final p = pet.species.toLowerCase(); // cão
                    return a.contains(p) || p.contains(a.replaceAll('s', '')); 
                  });

                  if (!isAccepted) {
                    return ListTile(
                      title: Text(pet.name, style: const TextStyle(color: Colors.grey)),
                      subtitle: Text("${pet.species} (Não aceite por este cuidador)", style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                      leading: const Icon(Icons.block, color: Colors.grey),
                    );
                  }

                  final isSelected = _selectedPetIds.contains(pet.id);

                  return CheckboxListTile(
                    activeColor: primaryPurple,
                    title: Text(pet.name),
                    subtitle: Text("${pet.species} • ${pet.breed ?? ''}"),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPetIds.add(pet.id);
                        } else {
                          _selectedPetIds.remove(pet.id);
                        }
                      });
                    },
                    secondary: CircleAvatar(
                      backgroundImage: pet.photo != null ? NetworkImage(pet.photo!) : null,
                      child: pet.photo == null ? const Icon(Icons.pets, size: 16) : null,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // --- 3. CALENDÁRIO (Disponibilidade Real) ---
            _buildSectionTitle("3. Escolha os dias", primaryPurple),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                locale: 'pt_PT',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.twoWeeks,
                availableCalendarFormats: const {CalendarFormat.twoWeeks: '2 Semanas', CalendarFormat.week: 'Semana'},
                
                selectedDayPredicate: (day) {
                  return _selectedDates.any((d) => isSameDay(d, day));
                },
                
                // LÓGICA DE BLOQUEIO DE DIAS
                enabledDayPredicate: (day) {
                  // Usa o working_schedule do provider!
                  if (widget.provider.schedule == null) return true; // Se não tiver horário, assume tudo aberto
                  return widget.provider.schedule!.isDayAvailable(day);
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    // Lógica de Toggle (Selecionar/Desselecionar)
                    if (_selectedDates.any((d) => isSameDay(d, selectedDay))) {
                      _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                    } else {
                      _selectedDates.add(selectedDay);
                    }
                  });
                },

                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: primaryPurple.withOpacity(0.3), shape: BoxShape.circle),
                  disabledTextStyle: const TextStyle(color: Colors.grey), // Dias bloqueados
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // --- 4. NOTAS ---
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Mensagem ou Cuidados Especiais",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => _clientNotes = v,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      
      // --- BARRA INFERIOR (RESUMO) ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Estimado", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(
                      "${_totalPrice.toStringAsFixed(2)}€", 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryPurple)
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _totalPrice > 0 ? _submitBooking : null, // Só ativa se tiver dados
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Enviar Pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }
}