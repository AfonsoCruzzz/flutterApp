import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/service_provider.dart';

class PetSitterCard extends StatelessWidget {
  final User user;
  final ServiceProvider provider;
  final VoidCallback onTap;
  
  // Callbacks opcionais para ações específicas (futuro)
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onBook;

  const PetSitterCard({
    super.key,
    required this.user,
    required this.provider,
    required this.onTap,
    this.onCall,
    this.onChat,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    // Paleta de Cores (Igual ao VeterinarianCard)
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    // 1. Calcular Preço Mínimo
    double minPrice = 0;
    if (provider.prices.isNotEmpty) {
      final prices = provider.prices.values.toList()..sort();
      minPrice = prices.first;
    }

    // 2. Localização
    String location = "Localização n/d";
    if (user.city != null && user.city!.isNotEmpty) {
      location = user.city!;
    } else if (user.district != null) {
      location = user.district!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Foto
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30), // Circular como no Vet
                      color: primaryPurple.withOpacity(0.1),
                    ),
                    child: user.photo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              user.photo!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.person, size: 30, color: primaryPurple.withOpacity(0.5)),
                  ),
                  const SizedBox(width: 16),

                  // 2. Info Principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Preço em destaque (substitui a "Clínica Geral" do Vet)
                        Text(
                          provider.prices.isEmpty ? "Sob Consulta" : "Desde ${minPrice.toStringAsFixed(0)}€",
                          style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Tags Roxas (Animais Aceites - Equivalente a Espécies)
                        if (provider.acceptedPets.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: provider.acceptedPets.take(3).map((pet) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: primaryPurple.withOpacity(0.3)),
                              ),
                              child: Text(
                                pet, 
                                style: const TextStyle(fontSize: 10, color: primaryPurple, fontWeight: FontWeight.w500),
                              ),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),

                  // 3. Rating e Status (Coluna da Direita)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              provider.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12),
                            ),
                            Text(
                              ' (${provider.ratingCount})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Status (Online/Ativo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: provider.isActive ? Colors.green : Colors.grey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: provider.isActive ? Colors.green : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              provider.isActive ? 'Ativo' : 'Oculto',
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: provider.isActive ? Colors.green : Colors.grey
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // --- TAGS LARANJA (SERVIÇOS) ---
              // Equivalente a Especialidades no Vet
              if (provider.serviceTypes.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: provider.serviceTypes.take(4).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ServiceProvider.getServiceLabel(service),
                        style: const TextStyle(
                          fontSize: 11,
                          color: primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 12),

              // --- LOCALIZAÇÃO ---
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Se tiveres cálculo de distância real, põe aqui
                  Text("~${provider.serviceRadiusKm} km raio", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),

              const SizedBox(height: 16),

              // --- BOTÕES DE AÇÃO ---
              Row(
                children: [
                  // Chat
                  _ActionButton(
                    icon: Icons.chat, 
                    label: "Chat", 
                    color: primaryPurple, 
                    isOutlined: true,
                    onTap: onChat ?? onTap,
                  ),
                  const SizedBox(width: 8),
                  
                  // Marcar (Botão Grande)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onBook ?? onTap, // Abre o perfil para marcar
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10), // Altura consistente
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text("Marcar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Auxiliar para os botões pequenos (Ligar/Chat)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.isOutlined, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Padding ajustado
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: color) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isOutlined ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}