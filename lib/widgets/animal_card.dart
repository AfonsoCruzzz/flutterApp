import 'package:flutter/material.dart';
import '../models/animal.dart';

class AnimalCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const AnimalCard({super.key, required this.animal, this.onTap, this.onEdit,});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto ou Ícone
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF3E5F5), // Light Purple
                backgroundImage: animal.photo != null ? NetworkImage(animal.photo!) : null,
                child: animal.photo == null 
                    ? const Icon(Icons.pets, color: Color(0xFF6A1B9A), size: 30) 
                    : null,
              ),
              const SizedBox(width: 16),
              // Detalhes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)
                      ),
                    ),
                    Text(
                      '${animal.species} • ${animal.breed ?? "Sem raça"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    // Badges (ex: Esterilizado)
                    Wrap(
                      spacing: 4,
                      children: [
                        if (animal.ageInYears != null)
                          _buildBadge('${animal.ageInYears} Anos', Colors.blue.shade50),
                        if (animal.isSterilized)
                          _buildBadge('Esterilizado', Colors.green.shade50),
                      ],
                    )
                  ],
                ),
              ),
              Column(
                children: [
                  // Botão Editar (Só aparece se passarmos a função onEdit)
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                      onPressed: onEdit, // <--- Chama a função
                      tooltip: 'Editar dados',
                      constraints: const BoxConstraints(), // Remove paddings extra
                      padding: EdgeInsets.zero,
                    ),
                  
                  // Se não houver onEdit, ou mesmo havendo, podemos mostrar a seta
                  if (onEdit == null)
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    );
  }
}