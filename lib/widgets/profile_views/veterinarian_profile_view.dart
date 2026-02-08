import 'package:flutter/material.dart';
import '../../models/veterinarian.dart';

class VeterinarianProfileView extends StatelessWidget {
  final Veterinarian veterinarian;

  const VeterinarianProfileView({super.key, required this.veterinarian});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Informações Profissionais
          _buildSectionTitle("Informações Profissionais", primaryPurple),
          _buildInfoRow(Icons.badge, "Cédula Profissional", veterinarian.licenseNumber),
          
          if (veterinarian.clinicName != null)
             _buildInfoRow(Icons.local_hospital, "Clínica", veterinarian.clinicName!),
          
          _buildInfoRow(Icons.work, "Regime", 
              veterinarian.serviceType == 'independent' ? "Independente" : 
              (veterinarian.serviceType == 'clinic' ? "Clínica" : "Misto")),

          const SizedBox(height: 24),

          // 2. Especialidades e Espécies
          if (veterinarian.specialties.isNotEmpty) ...[
            _buildSectionTitle("Especialidades", primaryPurple),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: veterinarian.specialties.map((s) => _buildChip(s, primaryPurple)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          if (veterinarian.services.isNotEmpty) ...[
               _buildSectionTitle("Serviços Disponíveis", const Color(0xFF6A1B9A)),
               Wrap(
                 spacing: 8, runSpacing: 8,
                 children: veterinarian.services.map((s) => _buildChip(s, Colors.green)).toList(),
               ),
               const SizedBox(height: 24),
          ],

          if (veterinarian.species.isNotEmpty) ...[
            _buildSectionTitle("Espécies que atende", primaryPurple),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: veterinarian.species.map((s) => _buildChip(s, Colors.blue)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Bio
          if (veterinarian.bio.isNotEmpty) ...[
            _buildSectionTitle("Biografia", primaryPurple),
            Text(veterinarian.bio, style: const TextStyle(height: 1.5, color: Colors.black87)),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                 Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
               ],
             )
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}