import 'package:flutter/material.dart';
import 'species_filter.dart';
import 'specialty_filter.dart';
import 'service_filter.dart'; // <--- Novo Import
import 'availability_filter.dart';

class FilterSection extends StatelessWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. ESPÉCIES
        SpeciesFilter(
          selectedSpecies: List<String>.from(filters['species'] ?? []),
          onSpeciesChanged: (newVal) => _updateFilter('species', newVal),
        ),
        const Divider(height: 32),

        // 2. ESPECIALIDADES
        SpecialtyFilter(
          selectedSpecialties: List<String>.from(filters['specialties'] ?? []),
          onSpecialtiesChanged: (newVal) => _updateFilter('specialties', newVal),
        ),
        const Divider(height: 32),

        // 3. SERVIÇOS (NOVO)
        ServiceFilter(
          selectedServices: List<String>.from(filters['services'] ?? []),
          onServicesChanged: (newVal) => _updateFilter('services', newVal),
        ),
        const Divider(height: 32),

        // 4. DISPONIBILIDADE
        AvailabilityFilter(
          availability: Map<String, dynamic>.from(filters['availability'] ?? {}),
          onAvailabilityChanged: (newVal) => _updateFilter('availability', newVal),
        ),
      ],
    );
  }

  void _updateFilter(String key, dynamic value) {
    final newFilters = Map<String, dynamic>.from(filters);
    newFilters[key] = value;
    onFiltersChanged(newFilters);
  }
}