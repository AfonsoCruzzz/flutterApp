import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart'; // Garante que tens o enum UserType aqui

class RoleUpgradeSheet extends StatefulWidget {
  final String userId;
  const RoleUpgradeSheet({super.key, required this.userId});

  @override
  State<RoleUpgradeSheet> createState() => _RoleUpgradeSheetState();
}

class _RoleUpgradeSheetState extends State<RoleUpgradeSheet> {
  final _supabase = Supabase.instance.client;
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);

  UserType? _selectedRole;
  bool _isUploading = false;
  File? _idDocumentFile;

  // Controllers para os campos específicos
  final _licenseController = TextEditingController();
  final _studentEmailController = TextEditingController();

  @override
  void dispose() {
    _licenseController.dispose();
    _studentEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _idDocumentFile = File(image.path);
      });
    }
  }

  // Função principal de submissão
  Future<void> _submitRequest() async {
    // 1. Validações Básicas
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um papel.')));
      return;
    }
    // O documento de identificação é obrigatório para TODOS os upgrades
    if (_idDocumentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O documento de identificação é obrigatório.')));
      return;
    }

    // Validações específicas
    if (_selectedRole == UserType.veterinarian && _licenseController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique a cédula profissional.')));
       return;
    }
    if (_selectedRole == UserType.student && _studentEmailController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique o email de estudante.')));
       return;
    }
    String roleToSave = _selectedRole!.name; // Isto dá 'serviceProvider'
      if (_selectedRole == UserType.serviceProvider) {
          roleToSave = 'provider'; // <--- Força 'provider'
    }

    setState(() => _isUploading = true);

    try {
      // 2. Upload do Documento para o Storage Privado
      final fileExt = _idDocumentFile!.path.split('.').last;
      final fileName = '${widget.userId}_id_doc_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // Nota: Usa o nome do teu bucket privado aqui
      await _supabase.storage.from('private_documents').upload(fileName, _idDocumentFile!);
      
      // Não podemos usar getPublicUrl num bucket privado. 
      // Guardamos apenas o caminho do ficheiro para o admin aceder depois via URL assinado.
      final filePath = fileName; 

      // 3. Atualizar a Base de Dados com o pedido
      await _supabase.from('profiles').update({
        'pending_role': roleToSave, // Guarda o que ele quer ser (ex: 'veterinarian')
        'verification_status': 'pending',
        'id_document_url': filePath, // Guarda o caminho do ficheiro
        
        // Guarda os dados específicos se aplicável, senão manda null para limpar
        'license_number': _selectedRole == UserType.veterinarian ? _licenseController.text.trim() : null,
        'student_email': _selectedRole == UserType.student ? _studentEmailController.text.trim() : null,

      }).eq('id', widget.userId);

      if (mounted) {
        Navigator.pop(context); // Fecha a sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pedido enviado para análise! Aguarde a verificação.'),
            backgroundColor: Colors.green[700],
          )
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao submeter: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Papéis disponíveis para upgrade (exclui 'client')
    final List<UserType> upgradeOptions = [
      UserType.veterinarian,
      UserType.serviceProvider,
      UserType.student,
    ];

    return Container(
      padding: EdgeInsets.only(
        top: 20, 
        left: 20, 
        right: 20,
        // Ajusta para o teclado não tapar os campos
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text('Evoluir na NinaVets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryPurple)),
            const Text('Escolha como quer contribuir e verifique a sua identidade.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // 1. Dropdown de Seleção de Papel
            DropdownButtonFormField<UserType>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Quero tornar-me...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.work_outline, color: primaryPurple),
              ),
              items: upgradeOptions.map((type) {
                String label = '';
                switch(type) {
                  case UserType.veterinarian: label = 'Médico Veterinário'; break;
                  case UserType.serviceProvider: label = 'Prestador de Serviços'; break;
                  case UserType.student: label = 'Estudante'; break;
                  default: label = '';
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRole = val;
                  _idDocumentFile = null; // Reseta a imagem se mudar de ideias
                });
              },
            ),
            const SizedBox(height: 24),

            // 2. Campos Dinâmicos (Aparecem conforme a escolha)
            if (_selectedRole != null) ...[
              
              // Campo específico: Veterinário
              if (_selectedRole == UserType.veterinarian) ...[
                TextFormField(
                  controller: _licenseController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nº Cédula Profissional *',
                    prefixIcon: Icon(Icons.badge, color: primaryPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo específico: Estudante
              if (_selectedRole == UserType.student) ...[
                TextFormField(
                  controller: _studentEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Institucional/Estudante *',
                    prefixIcon: Icon(Icons.school, color: primaryPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: "Enviaremos um código de verificação.",
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Upload do Documento (Obrigatório para TODOS os 3)
              const Divider(),
              const SizedBox(height: 8),
              Text('Verificação de Identidade *', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple)),
              const Text('Cartão de Cidadão ou documento equivalente.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _idDocumentFile != null 
                        ? DecorationImage(image: FileImage(_idDocumentFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _idDocumentFile == null 
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 40, color: primaryPurple),
                            const SizedBox(height: 8),
                            Text("Toque para carregar foto", style: TextStyle(color: primaryPurple)),
                          ],
                        )
                      : null,
                ),
              ),
              if (_idDocumentFile != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text("Documento selecionado.", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                 ),
              
              const SizedBox(height: 30),

              // 4. Botão de Submissão
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submeter Pedido para Análise", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}