import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Login bem-sucedido - navega para Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: user),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Email ou password incorretos';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Ícone
              const Icon(
                Icons.pets,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'NinaVets',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuidando dos seus animais',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Mensagem de erro
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
              
              // Campo Email
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
              
              // Campo Password
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
              const SizedBox(height: 24),
              
              // Botão Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Texto de demonstração
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contas de demonstração:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('vet@ninavets.pt / 123456'),
                    Text('student@ninavets.pt / 123456'),
                    Text('client@ninavets.pt / 123456'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Link para Registar
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Não tem conta? Registe-se aqui',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
