import 'package:flutter/material.dart';
import '../models/user.dart';
import 'profile_info_row.dart';
// IMPORTANTE: Importa o ecrã de edição de prestador
import 'role_upgrade_sheet.dart';

class ClientProfileView extends StatelessWidget {
  final User user;
  final bool isMyProfile;

  const ClientProfileView({
    super.key,
    required this.user,
    required this.isMyProfile,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF6A1B9A);
    final Color primaryOrange = const Color(0xFFFF6B35);

    // 1. LÓGICA DE TEXTO DO CARGO (CORREÇÃO)
    String roleLabel = 'Cliente / Tutor';
    if (user.type == UserType.serviceProvider) {
      roleLabel = 'Prestador de Serviços';
    } else if (user.type == UserType.student) {
      roleLabel = 'Estudante de Veterinária';
    }

    // Lógica de localização
    String locationText = "Não definida";
    if (user.district != null && user.city != null) {
      locationText = "${user.city}, ${user.district}";
    } else if (user.district != null) {
      locationText = user.district!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Cabeçalho
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryPurple.withOpacity(0.1),
            backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
            child: user.photo == null 
                ? Icon(Icons.person, size: 50, color: primaryPurple) 
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryPurple),
            textAlign: TextAlign.center,
          ),
          
          // AQUI USAMOS A VARIÁVEL roleLabel EM VEZ DO TEXTO FIXO
          Text(
            roleLabel, 
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),

         
          // ---------------------------------------------------------

          // Cartão de Dados Pessoais (Comum a todos)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Os meus dados pessoais', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryPurple)),
                  const Divider(),
                  
                  ProfileInfoRow(icon: Icons.email, label: 'Email', value: user.email),
                  ProfileInfoRow(icon: Icons.phone, label: 'Telefone', value: user.phone),
                  
                  if (user.district != null || user.city != null)
                     ProfileInfoRow(icon: Icons.map, label: 'Localização', value: locationText),
                  
                  if (user.address != null && user.address!.isNotEmpty)
                     ProfileInfoRow(icon: Icons.pin_drop, label: 'Morada', value: user.address),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // 3. CTA: EVOLUIR (Só aparece para CLIENTES)
          // Se eu já sou prestador, não preciso disto
          if (isMyProfile && user.type == UserType.client) 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryOrange.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryOrange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pets, size: 40, color: primaryOrange),
                  const SizedBox(height: 12),
                  Text(
                    "Quer fazer mais pelos animais?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Torne-se Veterinário, Estudante ou Prestador de Serviços na plataforma.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, 
                          backgroundColor: Colors.transparent,
                          builder: (context) => RoleUpgradeSheet(userId: user.id),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text("Alterar o meu Papel"),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}