import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/booking_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Supabase
  // Substitui pelos valores que copiaste do Dashboard (Settings -> API)
  await Supabase.initialize(
    url: 'https://egilkeawnyskkdlfuwnz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaWxrZWF3bnlza2tkbGZ1d256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4MTgzOTIsImV4cCI6MjA4NTM5NDM5Mn0.178gRzvrglQ4zxigPhJqB8vifL73gCo9Cf0rVhjG5JI',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NinaVets',
      theme: ThemeData(
        primaryColor: const Color(0xFF6A1B9A), // Roxo Principal
        
        // Definição do esquema de cores mantendo o teu design
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.purple,
          accentColor: const Color(0xFFFF6B35), // Laranja de destaque
        ),
        
        // Estilo base
        scaffoldBackgroundColor: Colors.white,
        
        // Tema da AppBar limpo (fundo branco, texto preto)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Recomendado para Flutter moderno (opcional)
      ),
      
      // O ponto de entrada da tua app
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
