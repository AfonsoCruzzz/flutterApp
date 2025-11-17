import 'package:flutter/material.dart';
import 'species_filter.dart';
import 'specialty_filter.dart';
import 'availability_filter.dart';

class FilterSection extends StatefulWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  late Map<String, dynamic> _localFilters;

  @override
  void initState() {
    super.initState();
    // Inicializar com tipos explícitos
    _localFilters = {
      'species': List<String>.from(widget.filters['species'] ?? <String>[]),
      'specialties': List<String>.from(widget.filters['specialties'] ?? <String>[]),
      'services': List<String>.from(widget.filters['services'] ?? <String>[]),
      'location': Map<String, dynamic>.from(widget.filters['location'] ?? {}),
      'availability': Map<String, dynamic>.from(widget.filters['availability'] ?? {}),
    };
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      _localFilters[key] = value;
    });
    widget.onFiltersChanged(_localFilters);
  }

  void _updateNestedFilter(String parentKey, String childKey, dynamic value) {
    setState(() {
      _localFilters[parentKey][childKey] = value;
    });
    widget.onFiltersChanged(_localFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limitar a 80% da altura
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // IMPORTANTE: evitar expandir indefinidamente
            children: [
              const Text(
                'Filtrar por:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 16),

              // 1. FILTRO DE ESPÉCIE
              SpeciesFilter(
                selectedSpecies: List<String>.from(_localFilters['species'] ?? <String>[]),
                onSpeciesChanged: (species) => _updateFilter('species', species),
              ),
              const SizedBox(height: 16),

              // 2. FILTRO DE ESPECIALIDADE  
              SpecialtyFilter(
                selectedSpecialties: List<String>.from(_localFilters['specialties'] ?? <String>[]),
                onSpecialtiesChanged: (specialties) => _updateFilter('specialties', specialties),
              ),
              const SizedBox(height: 16),

              // 3. FILTRO DE SERVIÇOS
              _buildServicesFilter(),
              const SizedBox(height: 16),

              // 4. FILTRO DE LOCALIZAÇÃO
              _buildLocationFilter(),
              const SizedBox(height: 16),

              // 5. FILTRO DE DISPONIBILIDADE
              AvailabilityFilter(
                availability: Map<String, dynamic>.from(_localFilters['availability'] ?? {}),
                onAvailabilityChanged: (availability) => _updateFilter('availability', availability),
              ),
              const SizedBox(height: 24),

              // BOTÃO LIMPAR FILTROS - SEMPRE VISÍVEL
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _localFilters = {
                    'species': <String>[],
                    'specialties': <String>[],
                    'services': <String>[],
                    'location': {'postalCode': '', 'distance': 25},
                    'availability': {'openNow': false, 'emergency24h': false},
                  };
                });
                widget.onFiltersChanged(_localFilters);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A1B9A),
                side: const BorderSide(color: Color(0xFF6A1B9A)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Limpar Filtros'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Os filtros já são aplicados automaticamente, mas podemos
                // adicionar uma confirmação extra se necessário
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filtros aplicados'),
                    backgroundColor: Color(0xFFFF6B35),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildServicesFilter() {
    const List<String> services = ['Urgência', 'Domicilio', 'Consulta', 'Telemedicina'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Serviço',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: services.map((service) {
            final List<String> currentServices = List<String>.from(_localFilters['services'] ?? <String>[]);
            final isSelected = currentServices.contains(service);
            
            return ChoiceChip(
              label: Text(
                service,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final List<String> updatedServices = List<String>.from(_localFilters['services'] ?? <String>[]);
                  if (selected) {
                    updatedServices.add(service);
                  } else {
                    updatedServices.remove(service);
                  }
                  _localFilters['services'] = updatedServices;
                });
                widget.onFiltersChanged(_localFilters);
              },
              selectedColor: const Color(0xFF6A1B9A),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF6A1B9A)),
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

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 8),
        
        // Input de código postal
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Código Postal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          onChanged: (value) => _updateNestedFilter('location', 'postalCode', value),
        ),
        const SizedBox(height: 16),
        
        // Slider de distância
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distância: ${_localFilters['location']['distance']} km',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Slider(
              value: (_localFilters['location']['distance'] ?? 25).toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${_localFilters['location']['distance']} km',
              onChanged: (value) => _updateNestedFilter('location', 'distance', value.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0 km'),
                Text('50 km'),
                Text('100 km'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}