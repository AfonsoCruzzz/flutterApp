import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/veterinarian.dart';
import '../services/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  final _formKey = GlobalKey<FormState>();

  Veterinarian? _vet;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers para os campos editáveis
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.user.type == UserType.veterinarian) {
      _loadVeterinarian();
    } else {
      // Para já, só tratamos veterinários
      _isLoading = false;
      _errorMessage =
          'O ecrã de perfil ainda só está disponível para veterinários.';
      setState(() {});
    }
  }

  Future<void> _loadVeterinarian() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vetBox = await LocalStorageService.veterinariansBox();
      final rawMap = vetBox.get(widget.user.id);

      if (rawMap == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Perfil de veterinário não encontrado.';
        });
        return;
      }

      final vet =
          Veterinarian.fromMap(Map<String, dynamic>.from(rawMap));

      _vet = vet;

      _phoneController.text = vet.phone;
      _addressController.text = vet.location.address;
      _cityController.text = vet.location.city;
      _bioController.text = vet.bio;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar o perfil. Tente novamente.';
      });
    }
  }

  Future<void> _saveVeterinarian() async {
    if (_vet == null) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final vetBox = await LocalStorageService.veterinariansBox();

      // Atualizar o objeto Veterinarian
      final updatedVet = Veterinarian(
        id: _vet!.id,
        name: _vet!.name,
        licenseNumber: _vet!.licenseNumber,
        email: _vet!.email,
        phone: _phoneController.text.trim(),
        photo: _vet!.photo,
        bio: _bioController.text.trim(),
        species: _vet!.species,
        specialties: _vet!.specialties,
        services: _vet!.services,
        availability: _vet!.availability,
        location: Location(
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          coordinates: _vet!.location.coordinates,
        ),
        rating: _vet!.rating,
        createdAt: _vet!.createdAt,
      );

      await vetBox.put(updatedVet.id, updatedVet.toMap());

      // Opcional: atualizar também o telefone no registo do utilizador (usersBox)
      try {
        final usersBox = await LocalStorageService.usersBox();
        final normalizedEmail = widget.user.email.trim().toLowerCase();
        final rawUserEntry = usersBox.get(normalizedEmail);

        if (rawUserEntry != null) {
          final userEntry =
              Map<String, dynamic>.from(rawUserEntry);
          final userMap = Map<String, dynamic>.from(
              (userEntry['user'] as Map?)?.cast<String, dynamic>() ?? {});

          userMap['phone'] = _phoneController.text.trim();
          userEntry['user'] = userMap;

          await usersBox.put(normalizedEmail, userEntry);
        }
      } catch (_) {
        // Se falhar aqui, não queremos rebentar o save principal
      }

      setState(() {
        _vet = updatedVet;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil atualizado com sucesso!'),
            backgroundColor: primaryPurple,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Erro ao guardar o perfil. Tente novamente.';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryPurple),
        titleTextStyle: TextStyle(
          color: primaryPurple,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_vet == null) {
      return const Center(
        child: Text('Dados do perfil não disponíveis.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card com info básica
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vet!.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tipo: Veterinário'),
                    Text('Email: ${_vet!.email}'),
                    if (_vet!.phone.isNotEmpty)
                      Text('Telefone: ${_vet!.phone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Dados profissionais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 12),

            // Cédula (só leitura)
            TextFormField(
              initialValue: _vet!.licenseNumber,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Cédula profissional',
                helperText: 'Definida no registo (não editável aqui).',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Morada',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Cidade',
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Sobre si',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio / Apresentação',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveVeterinarian,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'A guardar...' : 'Guardar alterações',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
