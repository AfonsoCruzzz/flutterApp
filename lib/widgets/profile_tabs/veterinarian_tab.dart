import 'package:flutter/material.dart';
import '../multi_select_chips.dart'; 
import '../../utils/veterinary_data.dart';
// NOVOS IMPORTS
import '../../models/working_schedule.dart';
import '../weekly_schedule_editor.dart';
import '../availability_calendar_manager.dart';

class VeterinarianTab extends StatelessWidget {
  final TextEditingController bioController;
  final TextEditingController clinicNameController;
  
  // Estados
  final String serviceType;
  final List<String> selectedSpecies;
  final List<String> selectedSpecialties;
  
  // --- NOVO: HORÁRIO E CALENDÁRIO ---
  final WorkingSchedule currentSchedule; 
  final Function(WorkingSchedule) onScheduleChanged;

  // Callbacks
  final Function(String?) onServiceTypeChanged;
  final Function(List<String>) onSpeciesChanged;
  final Function(List<String>) onSpecialtiesChanged;

  const VeterinarianTab({
    super.key,
    required this.bioController,
    required this.clinicNameController,
    required this.serviceType,
    required this.selectedSpecies,
    required this.selectedSpecialties,
    // Novos parâmetros
    required this.currentSchedule,
    required this.onScheduleChanged,
    
    required this.onServiceTypeChanged,
    required this.onSpeciesChanged,
    required this.onSpecialtiesChanged,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DADOS DA CLÍNICA
          const Text("Dados Profissionais", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryPurple)),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: serviceType,
            decoration: InputDecoration(
              labelText: 'Tipo de Serviço', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            ),
            items: const [
              DropdownMenuItem(value: 'clinic', child: Text('Exclusivo em Clínica')),
              DropdownMenuItem(value: 'independent', child: Text('Independente')),
              DropdownMenuItem(value: 'both', child: Text('Clínica + Independente')),
            ],
            onChanged: onServiceTypeChanged,
          ),
          const SizedBox(height: 16),
          
          if (serviceType != 'independent')
             TextFormField(
                controller: clinicNameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Clínica', 
                  prefixIcon: const Icon(Icons.local_hospital, color: primaryPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
             ),
          
          const SizedBox(height: 24),

          // 2. GESTÃO DE HORÁRIO (Injetado aqui)
          // Se for médico de clínica, talvez queiras esconder isto se ele seguir o horário da clínica,
          // mas assumindo que ele gere a sua agenda na app:
          
          // A. Editor Semanal
          WeeklyScheduleEditor(
            schedule: currentSchedule,
            onChanged: onScheduleChanged,
          ),

          const SizedBox(height: 32),

          // B. Editor de Exceções
          AvailabilityCalendarManager(
            schedule: currentSchedule,
            onChanged: onScheduleChanged,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 3. COMPETÊNCIAS TÉCNICAS
          const Text("Espécies que atende", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryPurple)),
          const SizedBox(height: 8),
          MultiSelectChips(
            options: VeterinaryData.speciesList, // Certifica-te que tens esta classe ou usa uma lista fixa
            selectedValues: selectedSpecies,
            activeColor: primaryOrange,
            onChanged: onSpeciesChanged,
          ),
          
          const SizedBox(height: 24),
          const Text("Especialidades", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryPurple)),
          const SizedBox(height: 8),
          MultiSelectChips(
             options: VeterinaryData.specialtiesList,
             selectedValues: selectedSpecialties,
             activeColor: primaryPurple,
             onChanged: onSpecialtiesChanged,
          ),
          
          const SizedBox(height: 24),

          // 4. BIO
          TextFormField(
            controller: bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Bio Profissional', 
              prefixIcon: const Icon(Icons.description, color: primaryPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}