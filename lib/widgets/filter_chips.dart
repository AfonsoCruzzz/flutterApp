import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;
  final Color selectedColor;
  final Color backgroundColor;

  const FilterChips({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
    required this.selectedColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        
        return ChoiceChip(
          label: Text(
            option,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : selectedColor,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<String>.from(selectedOptions);
            if (selected) {
              newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            onSelectionChanged(newSelection);
          },
          selectedColor: selectedColor,
          backgroundColor: backgroundColor,
          side: BorderSide(color: selectedColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}