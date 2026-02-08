import 'package:flutter/material.dart';
import '../models/working_schedule.dart';

class WeeklyScheduleEditor extends StatefulWidget {
  final WorkingSchedule schedule;
  final Function(WorkingSchedule) onChanged;

  const WeeklyScheduleEditor({
    super.key, 
    required this.schedule, 
    required this.onChanged
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  late Map<int, DaySchedule> _tempDays;
  final List<String> _dayLabels = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    // Clona o mapa para edição local
    _tempDays = Map.from(widget.schedule.days);
  }

  // Helper para mostrar TimePicker nativo
  Future<void> _pickTime(int dayIndex, bool isStart) async {
    final currentStr = isStart ? _tempDays[dayIndex + 1]!.start : _tempDays[dayIndex + 1]!.end;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6A1B9A)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Formata HH:mm com zero à esquerda
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        final oldDay = _tempDays[dayIndex + 1]!;
        _tempDays[dayIndex + 1] = isStart 
            ? oldDay.copyWith(start: formatted) 
            : oldDay.copyWith(end: formatted);
      });
      _notifyParent();
    }
  }

  void _notifyParent() {
    widget.onChanged(WorkingSchedule(days: _tempDays));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Horário de Disponibilidade", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)),
        const SizedBox(height: 8),
        const Text("Defina os dias e horas em que aceita serviços.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        
        // Lista de Dias
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (c, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // index 0 = Segunda (Chave 1 no mapa)
            final dayKey = index + 1;
            final schedule = _tempDays[dayKey] ?? DaySchedule();
            
            return Container(
              color: schedule.isOpen ? Colors.white : Colors.grey.shade50,
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: primaryPurple,
                    title: Text(_dayLabels[index], 
                        style: TextStyle(
                          fontWeight: schedule.isOpen ? FontWeight.bold : FontWeight.normal,
                          color: schedule.isOpen ? Colors.black : Colors.grey
                        )),
                    value: schedule.isOpen,
                    onChanged: (val) {
                      setState(() {
                        _tempDays[dayKey] = schedule.copyWith(isOpen: val);
                      });
                      _notifyParent();
                    },
                  ),
                  
                  // Se estiver aberto, mostra os seletores de hora
                  if (schedule.isOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeButton("Das", schedule.start, () => _pickTime(index, true)),
                          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          _buildTimeButton("Até às", schedule.end, () => _pickTime(index, false)),
                        ],
                      ),
                    )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text("$label ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.access_time, size: 14, color: Color(0xFF6A1B9A)),
          ],
        ),
      ),
    );
  }
}