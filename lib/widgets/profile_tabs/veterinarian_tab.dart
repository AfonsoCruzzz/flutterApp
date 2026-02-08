import 'package:flutter/material.dart';
import '../multi_select_chips.dart'; 
import '../../utils/veterinary_data.dart';
import '../../models/working_schedule.dart';
import '../weekly_schedule_editor.dart';
import '../availability_calendar_manager.dart';

class VeterinarianTab extends StatelessWidget {
  final TextEditingController bioController;
  final TextEditingController clinicNameController;
  // NOVO: Controlador para a morada de serviço
  final TextEditingController clinicAddressController; 
  
  // Estados
  final String serviceType;
  final List<String> selectedSpecies;
  final List<String> selectedSpecialties;
  // NOVO: Lista de serviços selecionados
  final List<String> selectedServices; 

  // Horário
  final WorkingSchedule currentSchedule; 
  final Function(WorkingSchedule) onScheduleChanged;

  // Callbacks
  final Function(String?) onServiceTypeChanged;
  final Function(List<String>) onSpeciesChanged;
  final Function(List<String>) onSpecialtiesChanged;
  // NOVO: Callback para serviços
  final Function(List<String>) onServicesChanged; 

  const VeterinarianTab({
    super.key,
    required this.bioController,
    required this.clinicNameController,
    required this.clinicAddressController, // <--- Receber no construtor
    required this.serviceType,
    required this.selectedSpecies,
    required this.selectedSpecialties,
    required this.selectedServices, // <--- Receber no construtor
    required this.currentSchedule,
    required this.onScheduleChanged,
    required this.onServiceTypeChanged,
    required this.onSpeciesChanged,
    required this.onSpecialtiesChanged,
    required this.onServicesChanged, // <--- Receber no construtor
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
          // 1. DADOS PROFISSIONAIS
          _buildSectionTitle("Dados Profissionais", primaryPurple),
          
          DropdownButtonFormField<String>(
            value: serviceType,
            decoration: _inputDecoration('Tipo de Serviço', Icons.work, primaryPurple),
            items: const [
              DropdownMenuItem(value: 'clinic', child: Text('Exclusivo em Clínica')),
              DropdownMenuItem(value: 'independent', child: Text('Independente (Domicílio)')),
              DropdownMenuItem(value: 'both', child: Text('Misto (Clínica + Domicílio)')),
            ],
            onChanged: onServiceTypeChanged,
          ),
          const SizedBox(height: 16),
          
          // Lógica: Se não for independente, pede dados da clínica
          if (serviceType != 'independent') ...[
             TextFormField(
                controller: clinicNameController,
                decoration: _inputDecoration('Nome da Clínica', Icons.local_hospital, primaryPurple),
             ),
             const SizedBox(height: 16),
             // NOVO: Morada da Clínica
             TextFormField(
                controller: clinicAddressController,
                decoration: _inputDecoration('Morada de Atendimento', Icons.location_on, primaryPurple).copyWith(
                  helperText: "Morada onde os clientes se devem dirigir.",
                ),
             ),
          ] else ...[
             // Mensagem informativa para independentes
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                   const SizedBox(width: 8),
                   Expanded(child: Text("Como independente, será usada a sua morada base ou área de serviço.", style: TextStyle(color: Colors.blue.shade900, fontSize: 13))),
                 ],
               ),
             )
          ],
          
          const SizedBox(height: 32),

          // 2. GESTÃO DE HORÁRIO (Com melhor contraste)
          _buildSectionTitle("Horário & Disponibilidade", primaryPurple),
          
          // Envolvemos num Card/Container para dar contraste aos toggles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50], // Fundo suave para destacar os switches brancos
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text("Defina a sua semana padrão", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                WeeklyScheduleEditor(
                  schedule: currentSchedule,
                  onChanged: onScheduleChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Calendário de Exceções
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: AvailabilityCalendarManager(
              schedule: currentSchedule,
              onChanged: onScheduleChanged,
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // 3. COMPETÊNCIAS TÉCNICAS
          // ESPÉCIES
          _buildSectionTitle("Espécies que atende", primaryPurple),
          MultiSelectChips(
            options: VeterinaryData.speciesList,
            selectedValues: selectedSpecies,
            activeColor: primaryOrange,
            onChanged: onSpeciesChanged,
          ),
          
          const SizedBox(height: 24),
          
          // ESPECIALIDADES
          _buildSectionTitle("Especialidades Médicas", primaryPurple),
          MultiSelectChips(
             options: VeterinaryData.specialtiesList,
             selectedValues: selectedSpecialties,
             activeColor: primaryPurple,
             onChanged: onSpecialtiesChanged,
          ),

          const SizedBox(height: 24),

          // NOVO: SERVIÇOS (Consultas, Vacinas, etc.)
          _buildSectionTitle("Serviços Disponíveis", primaryPurple),
          MultiSelectChips(
             options: const ['Consulta Geral', 'Vacinação', 'Desparasitação', 'Microchip', 'Cirurgia', 'Análises', 'Ecografia', 'Raio-X', 'Nutrição'], // Podes mover para VeterinaryData
             selectedValues: selectedServices,
             activeColor: Colors.green, // Verde para distinguir
             onChanged: onServicesChanged,
          ),
          
          const SizedBox(height: 24),

          // 4. BIO
          TextFormField(
            controller: bioController,
            maxLines: 4,
            decoration: _inputDecoration('Bio Profissional', Icons.description, primaryPurple).copyWith(alignLabelWithHint: true),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper para Títulos
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // Helper para Inputs
  InputDecoration _inputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}