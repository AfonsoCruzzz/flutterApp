import 'package:flutter/material.dart';
import '../../utils/veterinary_data.dart'; // Certifica-te que tens as listas aqui ou define-as localmente

class VeterinariansFilterScreen extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const VeterinariansFilterScreen({
    super.key,
    required this.initialFilters,
  });

  @override
  State<VeterinariansFilterScreen> createState() => _VeterinariansFilterScreenState();
}

class _VeterinariansFilterScreenState extends State<VeterinariansFilterScreen> {
  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);
  
  // Estado dos Filtros
  late List<String> _selectedSpecies;
  late List<String> _selectedServices;
  late List<String> _selectedSpecialties;
  late bool _emergencyOnly;
  late bool _homeVisitOnly; // Filtro para "Ao Domicílio"

  // Listas de Opções (Idealmente viriam de VeterinaryData, mas defino aqui para garantir funcionamento)
  final List<String> _speciesOptions = const ['Cães', 'Gatos', 'Exóticos', 'Aves', 'Equinos', 'Animais de Quinta'];
  final List<String> _servicesOptions = const ['Consulta Geral', 'Vacinação', 'Desparasitação', 'Microchip', 'Cirurgia', 'Análises', 'Ecografia', 'Raio-X', 'Nutrição'];
  final List<String> _specialtiesOptions = const ['Clínica Geral', 'Cirurgia', 'Dermatologia', 'Ortopedia', 'Cardiologia', 'Oftalmologia', 'Neurologia', 'Oncologia', 'Comportamento'];

  @override
  void initState() {
    super.initState();
    // Inicializar estado com base nos filtros recebidos
    _selectedSpecies = List<String>.from(widget.initialFilters['species'] ?? []);
    _selectedServices = List<String>.from(widget.initialFilters['services'] ?? []);
    _selectedSpecialties = List<String>.from(widget.initialFilters['specialties'] ?? []);
    
    final availability = widget.initialFilters['availability'] as Map? ?? {};
    _emergencyOnly = availability['emergency24h'] ?? false;
    _homeVisitOnly = availability['homeVisit'] ?? false;
  }

  void _applyFilters() {
    final newFilters = {
      'species': _selectedSpecies,
      'services': _selectedServices,
      'specialties': _selectedSpecialties,
      'availability': {
        'emergency24h': _emergencyOnly,
        'homeVisit': _homeVisitOnly,
      },
      // Mantemos a localização como estava ou adicionamos lógica de slider se necessário
      'location': widget.initialFilters['location'], 
    };
    Navigator.pop(context, newFilters);
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecies.clear();
      _selectedServices.clear();
      _selectedSpecialties.clear();
      _emergencyOnly = false;
      _homeVisitOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrar Veterinários', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: Text('Limpar', style: TextStyle(color: primaryOrange)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TIPO DE ATENDIMENTO
            _buildSectionTitle("Preferências de Atendimento"),
            SwitchListTile(
              title: const Text("Ao Domicílio"),
              subtitle: const Text("Apenas veterinários que se deslocam"),
              value: _homeVisitOnly,
              activeColor: primaryOrange,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _homeVisitOnly = val),
            ),
            SwitchListTile(
              title: const Text("Urgência 24h"),
              subtitle: const Text("Disponível para emergências"),
              value: _emergencyOnly,
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _emergencyOnly = val),
            ),
            
            const Divider(height: 32),

            // 2. ESPÉCIES
            _buildSectionTitle("Espécies"),
            const Text("Para que animal procura ajuda?", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _speciesOptions.map((s) => _buildFilterChip(s, _selectedSpecies)).toList(),
            ),

            const Divider(height: 32),

            // 3. SERVIÇOS (Novo filtro importante)
            _buildSectionTitle("Serviço"),
            const Text("Que tipo de ato médico precisa?", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _servicesOptions.map((s) => _buildFilterChip(s, _selectedServices, color: Colors.green)).toList(),
            ),

            const Divider(height: 32),

            // 4. ESPECIALIDADES
            _buildSectionTitle("Especialidade"),
            const Text("Procura um especialista específico?", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialtiesOptions.map((s) => _buildFilterChip(s, _selectedSpecialties, color: primaryPurple)).toList(),
            ),
            
            const SizedBox(height: 80), // Espaço para o botão
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Ver Resultados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
    );
  }

  Widget _buildFilterChip(String label, List<String> selectedList, {Color? color}) {
    final isSelected = selectedList.contains(label);
    final activeColor = color ?? const Color(0xFF6A1B9A);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            selectedList.add(label);
          } else {
            selectedList.remove(label);
          }
        });
      },
      selectedColor: activeColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.shade300,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}