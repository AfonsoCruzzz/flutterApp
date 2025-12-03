import 'package:flutter/material.dart';
import '../widgets/filter_section.dart';

class VeterinariansFilterScreen extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const VeterinariansFilterScreen({
    super.key,
    required this.initialFilters,
  });

  @override
  State<VeterinariansFilterScreen> createState() => _VeterinariansFilterScreenState();
}

class _VeterinariansFilterScreenState extends State<VeterinariansFilterScreen> {
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
        title: const Text('Filtrar Veterinários'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _activeFilters = {
                  'species': <String>[],
                  'specialties': <String>[],
                  'services': <String>[],
                  'location': {'postalCode': '', 'distance': 25},
                  'availability': {'openNow': false, 'emergency24h': false},
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
      body: FilterSection(
        filters: _activeFilters,
        onFiltersChanged: _updateFilters,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
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