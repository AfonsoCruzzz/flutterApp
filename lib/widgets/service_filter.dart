import 'package:flutter/material.dart';
import '../utils/veterinary_data.dart';

class ServiceFilter extends StatelessWidget {
  final List<String> selectedServices;
  final Function(List<String>) onServicesChanged;

  const ServiceFilter({
    super.key,
    required this.selectedServices,
    required this.onServicesChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Juntamos todos os serviços possíveis para o filtro
    final allServices = [...VeterinaryData.basicServices, ...VeterinaryData.clinicOnlyServices].toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Serviços', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: allServices.map((service) {
            final isSelected = selectedServices.contains(service);
            return FilterChip( // Usamos FilterChip aqui porque pode selecionar vários
              label: Text(service, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedServices);
                selected ? newSelection.add(service) : newSelection.remove(service);
                onServicesChanged(newSelection);
              },
              selectedColor: Colors.green,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
        ),
      ],
    );
  }
}