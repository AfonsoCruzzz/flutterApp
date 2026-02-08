import 'package:flutter/material.dart';
import '../multi_select_chips.dart'; // Importa o teu widget de chips existente
import '../../utils/veterinary_data.dart'; // Importa os dados estáticos

class VeterinarianTab extends StatelessWidget {
  final TextEditingController bioController;
  final TextEditingController clinicNameController;
  
  // Estados
  final String serviceType;
  final List<String> selectedSpecies;
  final List<String> selectedSpecialties;
  
  // Callbacks (Funções para avisar o pai)
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
          DropdownButtonFormField<String>(
            value: serviceType,
            decoration: InputDecoration(labelText: 'Tipo de Serviço', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
          const Text("Espécies que atende", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryPurple)),
          MultiSelectChips(
            options: VeterinaryData.speciesList,
            selectedValues: selectedSpecies,
            activeColor: primaryOrange,
            onChanged: onSpeciesChanged,
          ),
          
          const SizedBox(height: 24),
          const Text("Especialidades", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryPurple)),
          MultiSelectChips(
             options: VeterinaryData.specialtiesList,
             selectedValues: selectedSpecialties,
             activeColor: primaryPurple,
             onChanged: onSpecialtiesChanged,
          ),
          
          const SizedBox(height: 24),
          TextFormField(
            controller: bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Bio Profissional', 
              prefixIcon: const Icon(Icons.description, color: primaryPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}