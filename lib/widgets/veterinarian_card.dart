import 'package:flutter/material.dart';
import '../../models/veterinarian.dart';

class VeterinarianCard extends StatelessWidget {
  final Veterinarian veterinarian;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onBook;
  final VoidCallback? onTap;

  // Cores
  static const Color primaryPurple = Color(0xFF6A1B9A);
  static const Color primaryOrange = Color(0xFFFF6B35);

  const VeterinarianCard({
    super.key,
    required this.veterinarian,
    required this.onCall,
    required this.onChat,
    required this.onBook,
    this.onTap,
  });

  bool _isVeterinarianAvailable(Veterinarian vet) {
    // Por agora, usamos o campo isActive do modelo
    return vet.isActive;
  }

  @override
  Widget build(BuildContext context) {

    final Color primaryPurple = const Color(0xFF6A1B9A);
    final Color primaryOrange = const Color(0xFFFF6B35);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge, // Importante para o InkWell não sair fora
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com foto, nome e rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do veterinário
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: primaryPurple.withOpacity(0.1),
                  ),
                  child: veterinarian.photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            veterinarian.photo!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: primaryPurple.withOpacity(0.5),
                        ),
                ),
                const SizedBox(width: 16),
                
                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        veterinarian.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        veterinarian.specialties.isNotEmpty ? veterinarian.specialties.first : 'Médico Veterinário',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      
                      if (veterinarian.species.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: veterinarian.species.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryPurple.withOpacity(0.3)),
                            ),
                            child: Text(
                              s, 
                              style: TextStyle(fontSize: 10, color: primaryPurple, fontWeight: FontWeight.w500),
                            ),
                          )).toList(),
                        ),
                      const Divider(),
                      
                      // Especialidades (tags)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: veterinarian.specialties.take(3).map((specialty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                // Rating e disponibilidade
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            veterinarian.rating.average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${veterinarian.rating.reviews})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Indicador de disponibilidade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isVeterinarianAvailable(veterinarian) 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isVeterinarianAvailable(veterinarian)
                              ? Colors.green
                              : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: _isVeterinarianAvailable(veterinarian)
                                ? Colors.green
                                : Colors.grey,
                            size: 8,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isVeterinarianAvailable(veterinarian) ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isVeterinarianAvailable(veterinarian)
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Localização
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    veterinarian.location.address.isNotEmpty ? veterinarian.location.address : "Sem morada definida",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                // Botão Chat
                _ActionButton(
                  icon: Icons.chat, 
                  label: "Chat", 
                  color: primaryPurple, 
                  isOutlined: true,
                  onTap: onChat
                ),
                const SizedBox(width: 8),
                // Botão Marcar (Preenchido)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
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

// Widget auxiliar para botões pequenos
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.isOutlined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: color) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isOutlined ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}