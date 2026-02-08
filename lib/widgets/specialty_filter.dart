import 'package:flutter/material.dart';

class SpecialtyFilter extends StatelessWidget {
  final List<String> selectedSpecialties;
  final Function(List<String>) onSpecialtiesChanged;

  const SpecialtyFilter({
    super.key,
    required this.selectedSpecialties,
    required this.onSpecialtiesChanged,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> allSpecialties = [
      'Clínica Geral', 'Dermatologia', 'Cardiologia', 'Ortopedia',
      'Dentista', 'Oftalmologia', 'Neurologia', 'Cirurgia'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Especialidade',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: allSpecialties.map((specialty) {
            final isSelected = selectedSpecialties.contains(specialty);
            
            return ChoiceChip(
              label: Text(
                specialty,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : const Color(0xFFFF6B35),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedSpecialties);
                if (selected) {
                  newSelection.add(specialty);
                } else {
                  newSelection.remove(specialty);
                }
                onSpecialtiesChanged(newSelection);
              },
              selectedColor: const Color(0xFFFF6B35),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFFF6B35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }
}