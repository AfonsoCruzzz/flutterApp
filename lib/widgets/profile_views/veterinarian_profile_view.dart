import 'package:flutter/material.dart';
import '../../models/veterinarian.dart';
import '../../models/user.dart'; // Precisamos do User para a morada base

class VeterinarianProfileView extends StatelessWidget {
  final Veterinarian veterinarian;
  final User? userBase; // Passar o User base para mostrar a morada geral

  const VeterinarianProfileView({
    super.key, 
    required this.veterinarian,
    this.userBase, // Pode ser null se não tivermos acesso fácil, mas idealmente passamos
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    return SingleChildScrollView(
      // Padding bottom 120 para não ficar escondido atrás da navbar
      padding: const EdgeInsets.only(bottom: 120, left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Informações Profissionais e Localização
          _buildSectionTitle("Informações Profissionais", primaryPurple),
          
          // Cédula
          _buildInfoRow(Icons.badge, "Cédula Profissional", veterinarian.licenseNumber),
          
          // Regime e Clínica
          _buildInfoRow(Icons.work, "Regime", 
              veterinarian.serviceType == 'independent' ? "Independente" : 
              (veterinarian.serviceType == 'clinic' ? "Clínica" : "Misto")),
          
          if (veterinarian.clinicName != null)
             _buildInfoRow(Icons.local_hospital, "Clínica", veterinarian.clinicName!),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // --- GESTÃO DE MORADAS ---
          _buildSectionTitle("Localização", primaryPurple),
          
          // Morada Base (Do Cliente/User)
          if (userBase != null && userBase!.city != null)
             _buildInfoRow(Icons.home, "Morada Base (Domicílios)", "${userBase!.address ?? ''}, ${userBase!.city}"),

          // Morada da Clínica (Se existir e for diferente)
          if (veterinarian.clinicAddress != null && veterinarian.clinicAddress!.isNotEmpty)
             _buildInfoRow(Icons.location_on, "Morada de Atendimento (Clínica)", veterinarian.clinicAddress!, isHighlight: true),

          const SizedBox(height: 24),

          // 2. SERVIÇOS E ESPECIALIDADES (Chips)
          // Reorganizei para mostrar primeiro o que o cliente procura mais (Serviços)

          if (veterinarian.services.isNotEmpty) ...[
               _buildSectionTitle("Serviços Disponíveis", primaryPurple),
               Wrap(
                 spacing: 8, runSpacing: 8,
                 children: veterinarian.services.map((s) => _buildChip(s, Colors.green)).toList(),
               ),
               const SizedBox(height: 24),
          ],

          if (veterinarian.specialties.isNotEmpty) ...[
            _buildSectionTitle("Especialidades Médicas", primaryPurple),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: veterinarian.specialties.map((s) => _buildChip(s, primaryOrange)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          if (veterinarian.species.isNotEmpty) ...[
            _buildSectionTitle("Espécies que atende", primaryPurple),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: veterinarian.species.map((s) => _buildChip(s, primaryPurple)).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Bio
          if (veterinarian.bio.isNotEmpty) ...[
            _buildSectionTitle("Biografia", primaryPurple),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(veterinarian.bio, style: const TextStyle(height: 1.5, color: Colors.black87)),
            ),
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
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: isHighlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: isHighlight ? BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3))
      ) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isHighlight ? const Color(0xFFFF6B35) : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: TextStyle(fontSize: 12, color: isHighlight ? Colors.orange[800] : Colors.grey)),
                 const SizedBox(height: 2),
                 Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isHighlight ? Colors.black87 : Colors.black)),
               ],
             )
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color.withOpacity(1.0), fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}