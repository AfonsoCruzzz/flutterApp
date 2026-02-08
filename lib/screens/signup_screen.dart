import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- NOVO IMPORT
import '../providers/user_provider.dart'; // <--- NOVO IMPORT
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Controllers Específicos
  final _licenseController = TextEditingController(); // Para Veterinários
  final _studentNumberController = TextEditingController(); // Para Estudantes

  bool _isLoading = false;
  String _errorMessage = '';
  UserType _selectedUserType = UserType.client;

  // Cores
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color primaryOrange = const Color(0xFFFF6B35);
  final Color lightOrange = const Color(0xFFFFE8E0);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirme a password';
    if (value != _passwordController.text) return 'As passwords não coincidem';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Preparar os dados extras dependendo do tipo
      Map<String, dynamic>? extraData;

      if (_selectedUserType == UserType.veterinarian) {
        extraData = {
          'license_number': _licenseController.text.trim(),
        };
      } else if (_selectedUserType == UserType.student) {
        extraData = {
          'student_number': _studentNumberController.text.trim(),
        };
      } 

      // 2. Chamar o serviço de registo
      // Nota: O método register do AuthService deve criar o user no Supabase e na tabela profiles
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        type: _selectedUserType,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        extraData: extraData,
      );

      // 3. Obter os dados completos do utilizador recém-criado
      final user = await _authService.getCurrentUserData();

      if (mounted && user != null) {
        // --- A CORREÇÃO ESTÁ AQUI ---
        // Guardar o utilizador no estado global (Provider) ANTES de navegar
        context.read<UserProvider>().setUser(user);
        // ---------------------------

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        throw Exception("Erro ao carregar utilizador após registo.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _userTypeLabel(UserType type) {
    switch (type) {
      case UserType.veterinarian: return 'Veterinário(a)';
      case UserType.student: return 'Estudante';
      case UserType.serviceProvider: return 'Prestador de serviços';
      case UserType.client: return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 80, color: primaryPurple),
                const SizedBox(height: 20),
                Text(
                  'Criar conta',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryPurple),
                ),
                const SizedBox(height: 8),
                const Text('Junte-se à NinaVets', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),

                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightOrange,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryOrange),
                    ),
                    child: Text(_errorMessage, style: TextStyle(color: primaryOrange)),
                  ),

                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Nome', Icons.person),
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('Email', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<UserType>(
                  initialValue: _selectedUserType,
                  decoration: _buildInputDecoration('Tipo de utilizador', Icons.badge),
                  items: UserType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_userTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedUserType = value);
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedUserType == UserType.veterinarian) ...[
                  TextFormField(
                    controller: _licenseController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('Cédula Profissional', Icons.medical_services),
                    validator: (value) {
                       if (value == null || value.trim().isEmpty) return 'Obrigatório para veterinários';
                       if (value.length < 4) return 'Número inválido';
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedUserType == UserType.student) ...[
                  TextFormField(
                    controller: _studentNumberController,
                    keyboardType: TextInputType.text,
                    decoration: _buildInputDecoration('Número de Estudante', Icons.school),
                    validator: (value) {
                       if (value == null || value.trim().isEmpty) return 'Obrigatório para estudantes';
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _phoneController,
                  decoration: _buildInputDecoration('Telefone (opcional)', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildInputDecoration('Password', Icons.lock),
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _buildInputDecoration('Confirmar Password', Icons.lock_outline),
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _register(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryOrange)))
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Criar conta', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                ),
                
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Já tem conta? Faça login', style: TextStyle(color: primaryPurple)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryPurple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple, width: 2)),
      prefixIcon: Icon(icon, color: primaryPurple),
    );
  }
}