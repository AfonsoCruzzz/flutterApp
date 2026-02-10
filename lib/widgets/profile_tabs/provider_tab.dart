import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../models/working_schedule.dart'; // <--- Importante
import '../multi_select_chips.dart'; 
import '../weekly_schedule_editor.dart'; 
import '../availability_calendar_manager.dart';

class ProviderTab extends StatelessWidget {
  final TextEditingController bioController;
  
  // Mapas de estado
  final Map<String, bool> activeServices;
  final Map<String, TextEditingController> priceControllers;

  final TextEditingController addressController;
  final TextEditingController districtController;
  final TextEditingController municipalityController;
  
  // Logística e Casa
  final double radius;
  final bool hasTransport;
  final String housingType;
  final bool hasFencedYard;
  final bool hasOtherPets;
  
  // NOVOS CAMPOS
  final List<String> acceptedPets;
  final List<String> skills;
  
  // --- NOVO: HORÁRIO E CALENDÁRIO ---
  final WorkingSchedule currentSchedule; // Recebe o horário atual
  final Function(WorkingSchedule) onScheduleChanged; // Avisa quando muda

  // Callbacks
  final Function(String, bool) onServiceChanged;
  final Function(double) onRadiusChanged;
  final Function(bool) onTransportChanged;
  final Function(String?) onHousingChanged;
  final Function(bool) onFenceChanged;
  final Function(bool) onOtherPetsChanged;
  final Function(List<String>) onAcceptedPetsChanged;
  final Function(List<String>) onSkillsChanged;

  const ProviderTab({
    super.key,
    required this.bioController,
    required this.activeServices,
    required this.priceControllers,
    required this.radius,
    required this.hasTransport,
    required this.housingType,
    required this.hasFencedYard,
    required this.acceptedPets,
    required this.skills,
    // Novos campos no construtor
    required this.currentSchedule,
    required this.onScheduleChanged,
    
    required this.onServiceChanged,
    required this.onRadiusChanged,
    required this.onTransportChanged,
    required this.onHousingChanged,
    required this.onFenceChanged,
    required this.onAcceptedPetsChanged,
    required this.onSkillsChanged,
    required this.hasOtherPets,
    required this.onOtherPetsChanged,
    required this.addressController,
    required this.districtController,
    required this.municipalityController,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    // Helper para verificar se alojamento está ativo
    // (Verifica se existe e se é true, para evitar null errors)
    bool isHosting = (activeServices['pet_boarding'] ?? false) || (activeServices['pet_day_care'] ?? false);

    final List<String> petTypesOptions = ['Cães', 'Gatos', 'Coelhos', 'Pássaros', 'Répteis', 'Outros'];
    final List<String> skillsOptions = [
      'Administração de Medicamentos Orais',
      'Administração de Injetáveis',
      'Cuidados com Animais Séniores',
      'Cuidados com Animais Especiais',
      'Treino Básico / Obediência',
      'Primeiros Socorros',
      'Compreensão de Comportamento Reactivo',
      'Experiência com Raças Grandes',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. SERVIÇOS E PREÇOS ---
          _buildSectionTitle("Serviços & Tarifas", primaryPurple),
          const Text("Selecione os serviços que presta e defina o valor base.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          
          // Gera a lista de checkboxes
          Column(
            children: activeServices.keys.map((key) {
               final isActive = activeServices[key] ?? false;
               return AnimatedContainer(
                 duration: const Duration(milliseconds: 300),
                 margin: const EdgeInsets.only(bottom: 8),
                 decoration: BoxDecoration(
                   color: isActive ? primaryOrange.withOpacity(0.05) : Colors.white,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: isActive ? primaryOrange.withOpacity(0.5) : Colors.grey.shade300),
                 ),
                 child: Column(
                   children: [
                     CheckboxListTile(
                       title: Text(ServiceProvider.getServiceLabel(key), style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                       value: isActive,
                       activeColor: primaryOrange,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       onChanged: (v) => onServiceChanged(key, v ?? false),
                     ),
                     // Campo Expansível de Preço
                     if (isActive)
                       Padding(
                         padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                         child: Row(
                           children: [
                             const Text("Preço base: ", style: TextStyle(fontWeight: FontWeight.w500)),
                             const SizedBox(width: 10),
                             SizedBox(
                               width: 100,
                               child: TextFormField(
                                 controller: priceControllers[key],
                                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                 decoration: InputDecoration(
                                   hintText: "0.00",
                                   suffixText: '€', 
                                   isDense: true,
                                   contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), 
                                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                   filled: true,
                                   fillColor: Colors.white,
                                 ),
                               ),
                             ),
                             const SizedBox(width: 8),
                             Text(key.contains('walking') ? "/ passeio" : "/ dia", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                           ],
                         ),
                       )
                   ],
                 ),
               );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // --- 2. GESTÃO DE HORÁRIO (OS NOVOS WIDGETS) ---
          
          // A. Editor Semanal
          WeeklyScheduleEditor(
            schedule: currentSchedule, // Passamos o objeto recebido do pai
            onChanged: onScheduleChanged, // Passamos o callback do pai
          ),

          const SizedBox(height: 32),

          // B. Editor de Exceções (Calendário)
          AvailabilityCalendarManager(
            schedule: currentSchedule,
            onChanged: onScheduleChanged,
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // --- 3. ANIMAIS ACEITES ---
          _buildSectionTitle("Que animais aceita?", primaryPurple),
          MultiSelectChips(
            options: petTypesOptions,
            selectedValues: acceptedPets,
            activeColor: Colors.green,
            onChanged: onAcceptedPetsChanged,
          ),

          const SizedBox(height: 24),

          // --- 4. COMPETÊNCIAS / SKILLS ---
          _buildSectionTitle("As minhas Competências", primaryPurple),
          const Text("Destaque o que sabe fazer bem.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          MultiSelectChips(
            options: skillsOptions,
            selectedValues: skills,
            activeColor: primaryPurple,
            onChanged: onSkillsChanged,
          ),

          const SizedBox(height: 24),
          
          // --- 5. LOGÍSTICA ---
          _buildSectionTitle("Logística e Deslocação", primaryPurple),
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Column(
              children: [
                ListTile(
                  title: const Text("Raio de Atuação"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Até ${radius.round()} km da minha morada"),
                      Slider(
                        value: radius, min: 1, max: 50, divisions: 49,
                        activeColor: primaryOrange,
                        onChanged: onRadiusChanged,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text("Transporte de Emergência"), 
                  subtitle: const Text("Tenho viatura própria para urgências"),
                  value: hasTransport, 
                  activeColor: primaryOrange,
                  onChanged: onTransportChanged
                ),
              ],
            ),
          ),

          // --- 6. ALOJAMENTO (Condicional) ---
          if (isHosting) ...[
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_work, color: primaryPurple),
                      const SizedBox(width: 8),
                      Expanded( // <--- Adiciona este Expanded
                        child: Text(
                          "Localização do Espaço (Hotel/Casa)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: primaryPurple
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text("Como os clientes se deslocam até si, esta morada é obrigatória.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Morada do Espaço (Rua e Nº)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: districtController, decoration: const InputDecoration(labelText: "Distrito", border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: municipalityController, decoration: const InputDecoration(labelText: "Concelho", border: OutlineInputBorder(), filled: true, fillColor: Colors.white))),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Características", style: TextStyle(fontWeight: FontWeight.bold)),
                  
                  DropdownButtonFormField<String>(
                     value: housingType,
                     items: ['Apartamento', 'Moradia', 'Quinta', 'Hotel Pet'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                     onChanged: onHousingChanged,
                  ),
                  
                  CheckboxListTile(
                    title: const Text("Espaço Exterior Vedado"),
                    value: hasFencedYard, 
                    onChanged: (v) => onFenceChanged(v ?? false)
                  ),
                  
                  CheckboxListTile(
                    title: const Text("Tenho outros animais no espaço"),
                    subtitle: const Text("Assinale se tiver animais residentes"),
                    value: hasOtherPets,
                    onChanged: (v) => onOtherPetsChanged(v ?? false),
                  ),
                  if (hasOtherPets)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text("Nota: Descreva os seus animais na Bio abaixo.", style: TextStyle(color: primaryOrange, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // --- 7. BIO ---
          _buildSectionTitle("Sobre mim", primaryPurple),
          TextFormField(
            controller: bioController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Fale da sua experiência, porque gosta de animais e o que os donos podem esperar do seu serviço...', 
              prefixIcon: const Icon(Icons.description, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
    );
  }
}