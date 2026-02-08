import 'package:flutter/material.dart';
import '../utils/veterinary_data.dart'; // <--- Importa a lista central

class SpeciesFilter extends StatelessWidget {
  final List<String> selectedSpecies;
  final Function(List<String>) onSpeciesChanged;

  const SpeciesFilter({
    super.key,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Agora usamos a lista central. Se mudares lá, muda aqui automaticamente.
    final allSpecies = VeterinaryData.speciesList; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Espécie', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: allSpecies.map((species) {
            final isSelected = selectedSpecies.contains(species);
            return ChoiceChip(
              label: Text(species, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF6A1B9A))),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedSpecies);
                selected ? newSelection.add(species) : newSelection.remove(species);
                onSpeciesChanged(newSelection);
              },
              selectedColor: const Color(0xFF6A1B9A),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF6A1B9A)),
            );
          }).toList(),
        ),
      ],
    );
  }
}