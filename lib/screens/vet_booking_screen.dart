import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../models/veterinarian.dart';
import '../models/user.dart' as app_user;
import '../models/animal.dart';
import '../models/working_schedule.dart';

class VetBookingScreen extends StatefulWidget {
  final Veterinarian veterinarian;
  final app_user.User client;

  const VetBookingScreen({
    super.key,
    required this.veterinarian,
    required this.client,
  });

  @override
  State<VetBookingScreen> createState() => _VetBookingScreenState();
}

class _VetBookingScreenState extends State<VetBookingScreen> {
  final _supabase = Supabase.instance.client;
  
  // Estado
  String? _selectedService;
  List<String> _selectedPetIds = [];
  List<DateTime> _selectedDates = [];
  String _clientNotes = '';

  // Dados Auxiliares
  bool _isLoadingPets = true;
  List<Animal> _myPets = [];
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchClientPets();
  }

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
      if(mounted) setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedService == null) return _showError("Selecione o motivo da consulta.");
    if (_selectedPetIds.isEmpty) return _showError("Selecione o animal.");
    if (_selectedDates.isEmpty) return _showError("Escolha um dia.");

    try {
      _selectedDates.sort();

      final bookingData = {
        'client_id': widget.client.id,
        // Nota: O campo na BD pode ser 'provider_id' ou teres uma coluna 'vet_id' separada. 
        // Na arquitetura "Many Hats", se o Vet também é um Profile, usamos 'provider_id' como ID genérico do profissional.
        'provider_id': widget.veterinarian.id, 
        'service_type': _selectedService,
        'status': 'pending',
        'total_price': 0.0, // Vets geralmente não têm preço fixo tabelado na app ainda
        'scheduled_dates': _selectedDates.map((d) => d.toIso8601String().split('T')[0]).toList(),
        'client_notes': _clientNotes,
      };

      // 1. Criar Booking
      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      final String bookingId = response['id'];

      // 2. Associar Animais
      for (String petId in _selectedPetIds) {
        await _supabase.from('booking_animals').insert({
          'booking_id': bookingId,
          'animal_id': petId,
        });
      }

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pedido de consulta enviado!"), backgroundColor: Colors.green));
        Navigator.pop(context);
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
    const Color lightPurple = Color(0xFFF3E5F5);

    return Scaffold(
      appBar: AppBar(
        title: Text("Consulta: ${widget.veterinarian.name}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. TIPO DE SERVIÇO ---
            _buildSectionTitle("1. Motivo da Consulta", primaryPurple),
            if (widget.veterinarian.services.isEmpty)
               const Text("Consulta Geral", style: TextStyle(fontWeight: FontWeight.bold))
            else
              Wrap(
                spacing: 8,
                children: widget.veterinarian.services.map((service) {
                  final isSelected = _selectedService == service;
                  return ChoiceChip(
                    label: Text(service),
                    selected: isSelected,
                    selectedColor: primaryPurple.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? primaryPurple : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    onSelected: (val) => setState(() => _selectedService = val ? service : null),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 24),

            // --- 2. PACIENTE (ANIMAL) ---
            _buildSectionTitle("2. Paciente", primaryPurple),
            if (_isLoadingPets) 
              const Center(child: CircularProgressIndicator())
            else if (_myPets.isEmpty)
              const Text("Adicione animais ao seu perfil primeiro.")
            else
              Column(
                children: _myPets.map((pet) {
                  // FILTRO: O Vet atende esta espécie?
                  bool isAccepted = widget.veterinarian.species.any((s) {
                    final vetSpecies = s.toLowerCase();
                    final petSpecies = pet.species.toLowerCase();
                    // Lógica simples de match
                    return vetSpecies.contains(petSpecies) || petSpecies.contains(vetSpecies.replaceAll('s', ''));
                  });

                  // Se o vet não tiver espécies definidas, assumimos que atende tudo (fallback) ou bloqueamos.
                  // Vamos assumir que se a lista for vazia, ele atende clínica geral (tudo).
                  if (widget.veterinarian.species.isNotEmpty && !isAccepted) {
                    return ListTile(
                      title: Text(pet.name, style: const TextStyle(color: Colors.grey)),
                      subtitle: Text("Este médico não listou '${pet.species}' nas espécies atendidas.", style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                      leading: const Icon(Icons.block, color: Colors.grey),
                    );
                  }

                  final isSelected = _selectedPetIds.contains(pet.id);
                  return CheckboxListTile(
                    activeColor: primaryPurple,
                    title: Text(pet.name),
                    subtitle: Text("${pet.species} ${pet.breed != null ? '• ${pet.breed}' : ''}"),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                         // Vets normalmente veem 1 animal de cada vez, mas permitimos multi-seleção
                         if (val == true) _selectedPetIds.add(pet.id);
                         else _selectedPetIds.remove(pet.id);
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

            // --- 3. CALENDÁRIO ---
            _buildSectionTitle("3. Data Preferencial", primaryPurple),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                locale: 'pt_PT',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.twoWeeks,
                availableCalendarFormats: const {CalendarFormat.twoWeeks: '2 Semanas', CalendarFormat.week: 'Semana'},
                
                selectedDayPredicate: (day) => _selectedDates.any((d) => isSameDay(d, day)),
                
                // USAR O SCHEDULE DO VETERINÁRIO (Se existir)
                enabledDayPredicate: (day) {
                  // Se o modelo Veterinarian não tiver schedule, assumimos dias úteis ou tudo aberto
                  // Como adicionámos 'working_schedule' à tabela, mas tens de garantir que o objeto Dart o tem.
                  // Se não tiveres atualizado o model veterinarian.dart com o campo 'schedule', 
                  // remove esta linha 'availability' ou usa a lógica antiga.
                  // Assumindo que atualizaste conforme instruído:
                  // return widget.veterinarian.schedule?.isDayAvailable(day) ?? true;
                  
                  // Se ainda não atualizaste o model, usa isto temporariamente (apenas domingos fechados):
                  return day.weekday != DateTime.sunday; 
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    if (_selectedDates.any((d) => isSameDay(d, selectedDay))) {
                      _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                    } else {
                      // Para consultas, talvez queiras limitar a 1 dia
                      _selectedDates.clear(); 
                      _selectedDates.add(selectedDay);
                    }
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: primaryPurple.withOpacity(0.3), shape: BoxShape.circle),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 4. SINTOMAS / NOTAS ---
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Sintomas ou Motivo detalhado",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (v) => _clientNotes = v,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Valor Estimado", style: TextStyle(color: Colors.grey)),
                    Text("Sob Consulta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple, // Roxo para Vets
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Pedir Agendamento"),
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