import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  UserType _selectedType = UserType.client;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a password';
    }

    if (value != _passwordController.text) {
      return 'As passwords não coincidem';
    }

    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await AuthService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedType,
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Ocorreu um erro ao criar a conta.';
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
      case UserType.veterinarian:
        return 'Veterinário(a)';
      case UserType.student:
        return 'Estudante';
      case UserType.serviceProvider:
        return 'Prestador de serviços';
      case UserType.client:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.pets,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Junte-se à NinaVets',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: Validators.validateName,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo de utilizador',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge),
                ),
                items: UserType.values
                    .map(
                      (type) => DropdownMenuItem<UserType>(
                        value: type,
                        child: Text(_userTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: Validators.validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: _validateConfirmPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Criar conta',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                child: const Text(
                  'Já tem conta? Faça login',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
