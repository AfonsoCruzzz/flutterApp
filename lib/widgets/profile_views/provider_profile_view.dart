import 'package:flutter/material.dart';
import '../../models/service_provider.dart';

class ProviderProfileView extends StatelessWidget {
  final ServiceProvider provider;

  const ProviderProfileView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BIO
          if (provider.description.isNotEmpty) ...[
            _buildSectionTitle("Sobre mim", primaryPurple),
            Text(provider.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
            const SizedBox(height: 24),
          ],

          // 2. SERVIÇOS E PREÇOS (Lista bonita)
          _buildSectionTitle("Serviços & Tarifas", primaryPurple),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: provider.serviceTypes.map((key) {
                final price = provider.prices[key] ?? 0.0;
                final bool isLast = key == provider.serviceTypes.last;
                
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(_getServiceIcon(key), color: primaryOrange, size: 20),
                      ),
                      title: Text(ServiceProvider.getServiceLabel(key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: Text(
                        "${price.toStringAsFixed(2)}€${key.contains('walking') ? '' : '/dia'}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 70, endIndent: 20),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // 3. LOGÍSTICA (Cartões lado a lado)
          _buildSectionTitle("Logística", primaryPurple),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.map,
                  title: "Raio de Ação",
                  value: "${provider.serviceRadiusKm} km",
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.directions_car,
                  title: "Emergência",
                  value: provider.hasEmergencyTransport ? "Viatura Própria" : "Não incluído",
                  color: provider.hasEmergencyTransport ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. DETALHES DO ESPAÇO (Só se for hosting)
          if (provider.serviceTypes.contains('pet_boarding') || provider.serviceTypes.contains('pet_day_care')) ...[
            _buildSectionTitle("Onde o seu pet vai ficar", primaryPurple),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.home, "Tipo de Casa", provider.housingType),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.fence, "Espaço Exterior", provider.hasFencedYard ? "Sim, Vedado" : (provider.hasYard ? "Sim, não vedado" : "Não tem")),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.pets, "Outros Animais", provider.hasOtherPets ? "Tenho animais próprios" : "Sem outros animais"),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 5. SKILLS E PETS (Chips)
          if (provider.acceptedPets.isNotEmpty) ...[
             _buildSectionTitle("Animais Aceites", primaryPurple),
             Wrap(
               spacing: 8, runSpacing: 8,
               children: provider.acceptedPets.map((pet) => _buildChip(pet, Colors.green)).toList(),
             ),
             const SizedBox(height: 24),
          ],

          if (provider.skills.isNotEmpty) ...[
             _buildSectionTitle("Competências", primaryPurple),
             Wrap(
               spacing: 8, runSpacing: 8,
               children: provider.skills.map((skill) => _buildChip(skill, primaryPurple)).toList(),
             ),
             const SizedBox(height: 24),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
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

  IconData _getServiceIcon(String key) {
    switch (key) {
      case 'pet_boarding': return Icons.home;
      case 'dog_walking': return Icons.directions_walk;
      case 'pet_grooming': return Icons.content_cut;
      case 'pet_taxi': return Icons.local_taxi;
      default: return Icons.pets;
    }
  }
}