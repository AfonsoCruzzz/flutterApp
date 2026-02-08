import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/service_provider.dart';

class PetSitterCard extends StatelessWidget {
  final User user; // Dados pessoais (Nome, Foto, Morada)
  final ServiceProvider provider; // Dados de serviço (Preços, Rating)
  final VoidCallback onTap;

  const PetSitterCard({
    super.key,
    required this.user,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6A1B9A);
    final Color primaryOrange = const Color(0xFFFF6B35);
    final Color lightPurple = const Color(0xFFF3E5F5);

    // 1. Calcular Preço "A partir de"
    double minPrice = 0;
    if (provider.prices.isNotEmpty) {
      // Ordena os preços e pega no mais baixo
      final prices = provider.prices.values.toList()..sort();
      minPrice = prices.first;
    }

    // 2. Localização (Prioridade: Concelho > Distrito)
    String location = "Localização n/d";
    if (user.city != null && user.city!.isNotEmpty) {
      location = user.city!;
    } else if (user.district != null) {
      location = user.district!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FOTO ---
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: lightPurple,
                  image: user.photo != null 
                    ? DecorationImage(image: NetworkImage(user.photo!), fit: BoxFit.cover)
                    : null,
                ),
                child: user.photo == null 
                  ? Icon(Icons.person, size: 40, color: primaryPurple) 
                  : null,
              ),
              const SizedBox(width: 16),
              
              // --- CONTEÚDO ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome e Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryPurple),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: primaryOrange, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                provider.ratingAvg > 0 ? provider.ratingAvg.toStringAsFixed(1) : "Novato",
                                style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Localização
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Serviços (Chips pequenos)
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: provider.serviceTypes.take(3).map((s) {
                         return Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: primaryPurple.withOpacity(0.05),
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: primaryPurple.withOpacity(0.1))
                           ),
                           child: Text(
                             ServiceProvider.getServiceLabel(s),
                             style: TextStyle(fontSize: 10, color: primaryPurple),
                           ),
                         );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Preço
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.prices.isEmpty ? "Sob Consulta" : "Desde ${minPrice.toStringAsFixed(0)}€",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryOrange),
                        ),
                        Text("Ver Perfil >", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}