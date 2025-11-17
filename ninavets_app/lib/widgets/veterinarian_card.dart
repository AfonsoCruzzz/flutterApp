import 'package:flutter/material.dart';
import '../../models/veterinarian.dart';

class VeterinarianCard extends StatelessWidget {
  final Veterinarian veterinarian;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onBook;

  const VeterinarianCard({
    super.key,
    required this.veterinarian,
    required this.onCall,
    required this.onChat,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: const Color(0xFF6A1B9A).withOpacity(0.1),
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
                          color: const Color(0xFF6A1B9A).withOpacity(0.5),
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
                      
                      // Especialidades (tags)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: veterinarian.specialties.take(3).map((specialty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
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
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${veterinarian.location.address}, ${veterinarian.location.city}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                // TODO: Calcular e mostrar distância real
                const Text(
                  '~2.5 km',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6A1B9A),
                      side: const BorderSide(color: Color(0xFF6A1B9A)),
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Telefonar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B35),
                      side: const BorderSide(color: Color(0xFFFF6B35)),
                    ),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                    ),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Marcar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isVeterinarianAvailable(Veterinarian vet) {
    // Lógica simplificada - considerar disponível se tiver urgência ou se estiver dentro do horário
    final now = TimeOfDay.now();
    final start = _parseTime(vet.availability.businessHours.start);
    final end = _parseTime(vet.availability.businessHours.end);
    
    return vet.availability.emergency || 
           (now.hour >= start.hour && now.hour <= end.hour);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}