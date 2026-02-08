import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color primaryOrange = Color(0xFFFF6B35);

    return Scaffold(
      appBar: AppBar(
        title: Text(animal.name),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABEÇALHO (Foto e Info Básica) ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: primaryPurple.withOpacity(0.1),
                    backgroundImage: animal.photo != null ? NetworkImage(animal.photo!) : null,
                    child: animal.photo == null 
                        ? Icon(Icons.pets, size: 50, color: primaryPurple) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    animal.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  Text(
                    "${animal.species} • ${animal.breed ?? 'Sem raça'}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- INFO RÁPIDA (Grid) ---
            Row(
              children: [
                _buildInfoBox("Idade", animal.ageInYears != null ? "${animal.ageInYears} Anos" : "n/d", Icons.cake),
                const SizedBox(width: 12),
                _buildInfoBox("Peso", animal.weight != null ? "${animal.weight} kg" : "n/d", Icons.monitor_weight),
                const SizedBox(width: 12),
                _buildInfoBox("Sexo", animal.gender ?? "n/d", animal.gender == 'Fêmea' ? Icons.female : Icons.male),
              ],
            ),

            const SizedBox(height: 24),

            // --- SAÚDE E REGISTO ---
            _buildSectionTitle("Saúde & Registo", primaryPurple),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildRow("Microchip", animal.microchipNumber?.isNotEmpty == true ? animal.microchipNumber! : "Não registado"),
                  const Divider(),
                  _buildStatusRow("Esterilizado", animal.isSterilized),
                  const Divider(),
                  _buildStatusRow("Vacinação em Dia", animal.isVaccinated),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- COMPORTAMENTO ---
            if (animal.behavioralNotes != null && animal.behavioralNotes!.isNotEmpty) ...[
              _buildSectionTitle("Comportamento", primaryPurple),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(animal.behavioralNotes!, style: TextStyle(color: Colors.grey[800])),
              ),
              const SizedBox(height: 24),
            ],

            // --- NOTAS MÉDICAS ---
            if (animal.medicalNotes != null && animal.medicalNotes!.isNotEmpty) ...[
              _buildSectionTitle("Historial Médico", primaryPurple),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(animal.medicalNotes!, style: TextStyle(color: Colors.grey[800])),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  
  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.0)),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6A1B9A)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Row(
            children: [
              Icon(value ? Icons.check_circle : Icons.cancel, color: value ? Colors.green : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(value ? "Sim" : "Não", style: TextStyle(fontWeight: FontWeight.bold, color: value ? Colors.green : Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}