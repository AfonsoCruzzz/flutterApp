import 'dart:io';
import 'package:flutter/material.dart';

class GeneralTab extends StatelessWidget {
  // Dados
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController districtController;
  final TextEditingController municipalityController;
  final TextEditingController addressController;
  
  // Imagem
  final File? imageFile;
  final String? currentPhotoUrl;
  final VoidCallback onImagePick; // O pai diz o que acontece quando clica

  const GeneralTab({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.districtController,
    required this.municipalityController,
    required this.addressController,
    required this.imageFile,
    required this.currentPhotoUrl,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // FOTO DE PERFIL
          Center(
            child: GestureDetector(
              onTap: onImagePick,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!)
                        : (currentPhotoUrl != null ? NetworkImage(currentPhotoUrl!) as ImageProvider : null),
                    child: (imageFile == null && currentPhotoUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  const Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(radius: 16, backgroundColor: Color(0xFFFF6B35), child: Icon(Icons.camera_alt, size: 16, color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(controller: nameController, label: 'Nome', icon: Icons.person),
          const SizedBox(height: 16),
          _buildTextField(controller: phoneController, label: 'Telefone', icon: Icons.phone, inputType: TextInputType.phone),
          const SizedBox(height: 24),
          
          const Align(alignment: Alignment.centerLeft, child: Text("Localização Base", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple))),
          const SizedBox(height: 8),
          const Text("Esta localização será usada para todos os seus perfis.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildTextField(controller: districtController, label: 'Distrito *', icon: Icons.map)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(controller: municipalityController, label: 'Concelho *', icon: Icons.location_city)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Morada (Rua e Nº)',
              prefixIcon: const Icon(Icons.pin_drop, color: primaryPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: "Obrigatório para serviços de Hospedagem/Clínica",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (label.contains('*') && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
    );
  }
}