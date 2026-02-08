import 'package:flutter/material.dart' hide SearchBar;
import '../../../widgets/search_bar.dart';
import '../../../widgets/filter_chips.dart';

class PetSittingFilterSection extends StatefulWidget {
  final Map<String, dynamic> filters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const PetSittingFilterSection({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<PetSittingFilterSection> createState() => _PetSittingFilterSectionState();
}

class _PetSittingFilterSectionState extends State<PetSittingFilterSection> {
  late Map<String, dynamic> _localFilters;

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);
  final Color lightOrange = const Color(0xFFFFE8E0);
  final Color lightPurple = const Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _localFilters = Map<String, dynamic>.from(widget.filters);
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      _localFilters[key] = value;
    });
    widget.onFiltersChanged(_localFilters);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de busca
          SearchBar(
            hintText: 'Buscar por nome ou localização...',
            onChanged: (value) => _updateFilter('searchQuery', value),
            primaryColor: primaryPurple,
            lightColor: lightPurple,
          ),
          const SizedBox(height: 24),

          // Filtro de Espécies
          _buildSpeciesFilter(),
          const SizedBox(height: 24),

          // Filtro de Serviços
          _buildServicesFilter(),
          const SizedBox(height: 24),

          // Filtro de Preço
          _buildPriceFilter(),
        ],
      ),
    );
  }

  Widget _buildSpeciesFilter() {
    const List<String> species = ['Cães', 'Gatos', 'Aves', 'Peixes', 'Répteis', 'Roedores'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Espécies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 12),
        FilterChips(
          options: species,
          selectedOptions: List<String>.from(_localFilters['species'] ?? <String>[]),
          onSelectionChanged: (species) => _updateFilter('species', species),
          selectedColor: primaryPurple,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildServicesFilter() {
    const List<String> services = ['Passeios', 'Hospedagem', 'Visitas', 'Creche', 'Adestramento'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Serviços',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 12),
        FilterChips(
          options: services,
          selectedOptions: List<String>.from(_localFilters['services'] ?? <String>[]),
          onSelectionChanged: (services) => _updateFilter('services', services),
          selectedColor: primaryOrange,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preço máximo por dia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '\$${_localFilters['maxPrice']?.toStringAsFixed(0) ?? '100'}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 16),
        Slider(
          value: (_localFilters['maxPrice'] ?? 100.0).toDouble(),
          min: 20,
          max: 200,
          divisions: 18,
          label: '\$${_localFilters['maxPrice']?.toStringAsFixed(0)}',
          onChanged: (value) => _updateFilter('maxPrice', value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('\$20'),
            Text('\$110'),
            Text('\$200'),
          ],
        ),
      ],
    );
  }
}