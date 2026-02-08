import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Certifica-te que tens o pacote 'intl' no pubspec.yaml

import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../providers/user_provider.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animalToEdit; // <--- ADICIONA ISTO

  const AddAnimalScreen({super.key, this.animalToEdit}); // <--- ATUALIZA ISTO

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  // Controladores
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _medicalController = TextEditingController();
  final _dateController = TextEditingController();

  // Estado
  File? _imageFile;
  bool _isUploading = false;
  
  // Valores por defeito
  String _species = 'Cão';
  String _gender = 'Macho';
  DateTime? _birthDate;
  bool _isSterilized = false;
  bool _isVaccinated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _behaviorController.dispose();
    _medicalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Variável para guardar a foto antiga (adiciona isto às variáveis da classe State)
  String? _currentPhotoUrl; 

  @override
  void initState() {
    super.initState();
    
    // --- ADICIONA ESTE BLOCO ---
    if (widget.animalToEdit != null) {
      final a = widget.animalToEdit!;
      
      // Preencher os controladores com os dados do animal
      _nameController.text = a.name;
      _breedController.text = a.breed ?? '';
      _weightController.text = a.weight?.toString() ?? '';
      _microchipController.text = a.microchipNumber ?? '';
      _behaviorController.text = a.behavioralNotes ?? '';
      _medicalController.text = a.medicalNotes ?? '';
      
      // Preencher as variáveis de estado
      _species = a.species;
      _gender = a.gender ?? 'Macho';
      _birthDate = a.birthDate;
      _isSterilized = a.isSterilized;
      _isVaccinated = a.isVaccinated;
      _currentPhotoUrl = a.photo; // Guardar a foto antiga para não a perderes

      // Se houver data, meter no texto para o user ver
      if (a.birthDate != null) {
        _dateController.text = DateFormat('dd/MM/yyyy').format(a.birthDate!);
      }
    }
    // ---------------------------
  }
  // --- Lógica de Imagem ---
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Comprime logo para poupar dados
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar foto: $e')));
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;
    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // NOTA: Tens de criar um bucket chamado 'animals' no Supabase Storage
      await _supabase.storage.from('animals').upload(
        fileName,
        _imageFile!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from('animals').getPublicUrl(fileName);
    } catch (e) {
      print('Erro upload animal: $e');
      throw Exception('Falha ao enviar foto do animal');
    }
  }

  // --- Lógica de Data ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)), // Começa há 1 ano atrás
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              onSurface: primaryPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // --- Gravar ---
  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final user = context.read<UserProvider>().currentUser!;
      
      // 1. Upload da foto (se existir)
      String? photoUrl = _imageFile != null 
          ? await _uploadImage(user.id) // Fez upload de nova
          : _currentPhotoUrl;           // Mantém a que já tinha

      // 2. Criar objeto
      final animalData = Animal(
        id: widget.animalToEdit?.id ?? '', // <--- IMPORTANTE: Manter o ID se for edição
        ownerId: user.id,
        name: _nameController.text.trim(),
        species: _species,
        breed: _breedController.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
        weight: double.tryParse(_weightController.text.replaceAll(',', '.')),
        microchipNumber: _microchipController.text.trim(),
        isSterilized: _isSterilized,
        isVaccinated: _isVaccinated,
        behavioralNotes: _behaviorController.text.trim(),
        medicalNotes: _medicalController.text.trim(),
        photo: photoUrl, // <--- Usa a variável correta
      );

      // Decisão: Criar ou Atualizar?
      if (widget.animalToEdit == null) {
        // Modo Criação
        await context.read<AnimalProvider>().addAnimal(animalData, user.id);
      } else {
        // Modo Edição (Tens de ter criado o updateAnimal no Provider primeiro!)
        await context.read<AnimalProvider>().updateAnimal(animalData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Perfil de Animal'),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50], // Fundo ligeiramente cinza para destacar os cards
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- FOTO ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          border: Border.all(color: primaryPurple, width: 2),
                          image: _imageFile != null
                              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imageFile == null
                            ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryOrange,
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- DADOS PRINCIPAIS ---
              _buildSectionTitle('Identidade'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Nome do Animal *', Icons.pets),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => v!.isEmpty ? 'O nome é obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _species,
                              decoration: _inputDecoration('Espécie', Icons.category),
                              items: ['Cão', 'Gato', 'Ave', 'Coelho', 'Outro']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _species = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _breedController,
                              decoration: _inputDecoration('Raça', Icons.search),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // SEXO (Segmented Control Simples)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Género', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildGenderOption('Macho', Icons.male),
                              const SizedBox(width: 16),
                              _buildGenderOption('Fêmea', Icons.female),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- DADOS BIOMÉTRICOS ---
              _buildSectionTitle('Dados Físicos'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: _inputDecoration('Nascimento', Icons.cake),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: _inputDecoration('Peso (kg)', Icons.monitor_weight),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- SAÚDE ---
              _buildSectionTitle('Saúde & Registo'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _microchipController,
                        decoration: _inputDecoration('Nº Microchip', Icons.qr_code),
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Esterilizado(a)?'),
                      subtitle: const Text('Importante para convívio com outros animais'),
                      value: _isSterilized,
                      activeColor: primaryOrange,
                      secondary: Icon(Icons.content_cut, color: primaryPurple),
                      onChanged: (v) => setState(() => _isSterilized = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Vacinação em Dia?'),
                      value: _isVaccinated,
                      activeColor: primaryOrange,
                      secondary: Icon(Icons.vaccines, color: primaryPurple),
                      onChanged: (v) => setState(() => _isVaccinated = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- NOTAS ---
              _buildSectionTitle('Observações'),
              TextFormField(
                controller: _behaviorController,
                decoration: _inputDecoration('Comportamento (Medos, hábitos...)', Icons.psychology).copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicalController,
                decoration: _inputDecoration('Notas Médicas (Alergias, medicação...)', Icons.medical_services).copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 40),

              // --- BOTÃO DE AÇÃO ---
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveAnimal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Salvar Perfil',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, IconData icon) {
    final isSelected = _gender == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryPurple.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? primaryPurple : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? primaryPurple : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryPurple : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryPurple.withOpacity(0.7), size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}