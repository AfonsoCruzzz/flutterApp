import 'package:flutter/material.dart';

class MultiSelectChips extends StatelessWidget {
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final Color activeColor;

  const MultiSelectChips({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.activeColor = const Color(0xFF6A1B9A),
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return FilterChip(
          label: Text(
            option,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: activeColor,
          backgroundColor: Colors.grey[100],
          checkmarkColor: Colors.white,
          onSelected: (bool selected) {
            final newValues = List<String>.from(selectedValues);
            if (selected) {
              newValues.add(option);
            } else {
              newValues.remove(option);
            }
            onChanged(newValues);
          },
        );
      }).toList(),
    );
  }
}