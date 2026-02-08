import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/working_schedule.dart';

class AvailabilityCalendarManager extends StatefulWidget {
  final WorkingSchedule schedule;
  final Function(WorkingSchedule) onChanged;

  const AvailabilityCalendarManager({
    super.key,
    required this.schedule,
    required this.onChanged,
  });

  @override
  State<AvailabilityCalendarManager> createState() => _AvailabilityCalendarManagerState();
}

class _AvailabilityCalendarManagerState extends State<AvailabilityCalendarManager> {
  late List<DateTime> _blockedDates;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _blockedDates = List.from(widget.schedule.blockedDates);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;

      // 1. Verificar se é um dia de trabalho normal
      final dayConfig = widget.schedule.days[selectedDay.weekday];
      final isNormallyOpen = dayConfig?.isOpen ?? false;

      // Se o dia já está fechado pela regra base (ex: Domingo), não fazemos nada
      // (Ou podíamos permitir abrir excecionalmente, mas vamos manter simples: só bloquear dias abertos)
      if (!isNormallyOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este dia já está fechado pelo seu horário semanal.")),
        );
        return;
      }

      // 2. Toggle Bloqueio
      final isBlocked = _blockedDates.any((d) => _isSameDay(d, selectedDay));

      if (isBlocked) {
        // Desbloquear
        _blockedDates.removeWhere((d) => _isSameDay(d, selectedDay));
      } else {
        // Bloquear
        _blockedDates.add(selectedDay);
      }

      // 3. Notificar Pai
      widget.onChanged(
        WorkingSchedule(
          days: widget.schedule.days, 
          blockedDates: _blockedDates
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color errorColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Exceções e Folgas", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)
        ),
        const SizedBox(height: 8),
        const Text(
          "Toque num dia verde para bloquear a agenda (ex: Férias, Médico).",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TableCalendar(
            locale: 'pt_PT', // Certifica-te que tens a localização configurada no main.dart
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            
            // Estilo do Cabeçalho
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),

            // Lógica de Seleção
            onDaySelected: _onDaySelected,
            selectedDayPredicate: (day) => false, // Não queremos o círculo de seleção azul padrão

            // Construtor dos Dias (A parte visual importante)
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                final isNormallyOpen = widget.schedule.days[date.weekday]?.isOpen ?? false;
                final isBlocked = _blockedDates.any((d) => _isSameDay(d, date));

                if (isBlocked) {
                  // Dia Bloqueado (Exceção) -> VERMELHO
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(6.0),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Center(child: Text('${date.day}', style: const TextStyle(color: Colors.white))),
                    ),
                  );
                } else if (isNormallyOpen) {
                  // Dia Aberto (Regra) -> VERDE SUAVE
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
                      child: Center(child: Text('${date.day}', style: const TextStyle(color: Colors.green))),
                    ),
                  );
                } else {
                  // Dia Fechado (Regra) -> CINZENTO
                  return Center(
                     child: Text('${date.day}', style: const TextStyle(color: Colors.grey)),
                  );
                }
              },
              
              // Estilo para hoje
              todayBuilder: (context, date, _) {
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryPurple),
                      shape: BoxShape.circle
                    ),
                    child: Center(child: Text('${date.day}', style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        // Legenda
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.green.withOpacity(0.2), "Disponível"),
            _buildLegendItem(Colors.redAccent, "Bloqueado"),
            _buildLegendItem(Colors.grey.withOpacity(0.2), "Folga Semanal"),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}