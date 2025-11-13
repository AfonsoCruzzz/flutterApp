import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class ServiceProvidersScreen extends StatefulWidget {
  const ServiceProvidersScreen({super.key});

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  late Future<List<User>> _providersFuture;

  @override
  void initState() {
    super.initState();
    _providersFuture = AuthService.fetchServiceProviders();
  }

  Future<void> _refresh() async {
    setState(() {
      _providersFuture = AuthService.fetchServiceProviders();
    });
    await _providersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passear'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<User>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ocorreu um erro ao carregar os prestadores de serviços',
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            );
          }

          final providers = snapshot.data ?? [];

          if (providers.isEmpty) {
            return const Center(
              child: Text(
                'Ainda não existem prestadores de serviços registados.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = providers[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: const Icon(
                        Icons.directions_walk,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user.email}'),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          Text('Telefone: ${user.phone}'),
                        if (user.createdAt != null)
                          Text('Registado em: ${_formatDate(user.createdAt!)}'),
                      ],
                    ),
                    onTap: () => _openBookingSheet(user),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBookingSheet(User provider) async {
    final request = await showModalBottomSheet<_BookingRequest>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BookingRequestSheet(provider: provider),
    );

    if (!mounted || request == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pedido enviado para ${provider.name}. Será notificado em breve.',
        ),
      ),
    );
  }
}

class _BookingRequest {
  const _BookingRequest({
    required this.petName,
    required this.date,
    required this.price,
  });

  final String petName;
  final DateTime date;
  final String price;
}

class _BookingRequestSheet extends StatefulWidget {
  const _BookingRequestSheet({required this.provider});

  final User provider;

  @override
  State<_BookingRequestSheet> createState() => _BookingRequestSheetState();
}

class _BookingRequestSheetState extends State<_BookingRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = _formatDate(pickedDate);
      });
    }
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null) {
      return;
    }

    final request = _BookingRequest(
      petName: _nameController.text.trim(),
      date: _selectedDate!,
      price: _priceController.text.trim(),
    );

    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solicitar Passeio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text('Prestador: ${widget.provider.name}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do animal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indique o nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Data do passeio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Selecione a data',
                ),
                validator: (_) {
                  if (_selectedDate == null) {
                    return 'Selecione a data.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indique um valor.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Um sistema de notificações real pode ser integrado posteriormente.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}
