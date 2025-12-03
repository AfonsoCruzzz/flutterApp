import 'package:flutter/material.dart';
import '../widgets/pet_sitting_filter_section.dart';

class PetSittingSearchScreen extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const PetSittingSearchScreen({
    super.key,
    required this.initialFilters,
  });

  @override
  State<PetSittingSearchScreen> createState() => _PetSittingSearchScreenState();
}

class _PetSittingSearchScreenState extends State<PetSittingSearchScreen> {
  late Map<String, dynamic> _activeFilters;

  @override
  void initState() {
    super.initState();
    _activeFilters = Map<String, dynamic>.from(widget.initialFilters);
  }

  void _updateFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrar Pet Sitters'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Limpar todos os filtros
              setState(() {
                _activeFilters = {
                  'searchQuery': '',
                  'species': <String>[],
                  'services': <String>[],
                  'maxPrice': 100.0,
                };
              });
            },
            child: Text(
              'Limpar',
              style: TextStyle(color: const Color(0xFF6A1B9A)),
            ),
          ),
        ],
      ),
      body: PetSittingFilterSection(
        filters: _activeFilters,
        onFiltersChanged: _updateFilters,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Retornar os filtros para a página anterior
            Navigator.pop(context, _activeFilters);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Aplicar Filtros',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}