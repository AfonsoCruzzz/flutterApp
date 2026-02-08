import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ninavets_app/services/auth_service.dart'; // Ajusta o import para o teu projeto
import 'package:ninavets_app/models/user.dart' as app_user;

// Gera os Mocks necessários para simular o Supabase
@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<GoTrueClient>(),
  MockSpec<SupabaseQueryBuilder>(),
  MockSpec<PostgrestFilterBuilder>(),
  MockSpec<PostgrestTransformBuilder>(),
  MockSpec<User>(), // User do Supabase
  MockSpec<AuthResponse>(),
])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late MockPostgrestTransformBuilder mockTransformBuilder;

  setUp(() {
    // Inicializar os mocks
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockTransformBuilder = MockPostgrestTransformBuilder();

    // Configurar o comportamento base do cliente Supabase
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);

    // Injetar o mock no nosso serviço
    authService = AuthService(client: mockSupabaseClient);
  });

  group('AuthService - Login', () {
    test('deve retornar um app_user.User quando o login é bem sucedido', () async {
      // DADOS DE TESTE
      const email = 'teste@ninavets.pt';
      const password = '123456';
      const userId = 'user-123';

      // 1. SIMULAR RESPOSTA DO LOGIN (Auth)
      final mockAuthResponse = MockAuthResponse();
      final mockSupabaseUser = MockUser();
      
      when(mockSupabaseUser.id).thenReturn(userId);
      when(mockSupabaseUser.email).thenReturn(email);
      when(mockAuthResponse.user).thenReturn(mockSupabaseUser);

      // Quando chamar signInWithPassword, devolve sucesso
      when(mockGoTrueClient.signInWithPassword(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockAuthResponse);

      // 2. SIMULAR RESPOSTA DA BASE DE DADOS (Profiles)
      // A cadeia é: from('profiles').select().eq('id', ...).single()
      
      // O dado que a "base de dados" devolve
      final profileData = {
        'id': userId,
        'email': email,
        'full_name': 'João Teste',
        'role': 'client',
        'phone': '911111111',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Configurar a cadeia de mocks da query
      when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => profileData);

      // EXECUÇÃO
      final result = await authService.login(email, password);

      // VERIFICAÇÃO
      expect(result, isNotNull);
      expect(result!.id, userId);
      expect(result.name, 'João Teste');
      expect(result.type, app_user.UserType.client);
      
      // Verificar se chamou os métodos certos
      verify(mockGoTrueClient.signInWithPassword(email: email, password: password)).called(1);
    });

    test('deve lançar erro se o login falhar', () async {
      when(mockGoTrueClient.signInWithPassword(
        email: any,
        password: any,
      )).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => authService.login('bad@email.com', 'wrongpass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - Register', () {
    test('deve criar utilizador e inserir tabelas corretas para Veterinário', () async {
      const email = 'vet@ninavets.pt';
      const userId = 'vet-123';

      // 1. Simular Criação de Auth
      final mockAuthResponse = MockAuthResponse();
      final mockSupabaseUser = MockUser();
      when(mockSupabaseUser.id).thenReturn(userId);
      when(mockAuthResponse.user).thenReturn(mockSupabaseUser);

      when(mockGoTrueClient.signUp(
        email: email,
        password: any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockAuthResponse);

      // 2. Simular Inserts na BD
      // O insert não retorna nada no teu código, apenas Future<void> ou erro
      when(mockQueryBuilder.insert(any)).thenAnswer((_) async => []); 

      // EXECUÇÃO
      await authService.register(
        email: email,
        password: 'password',
        name: 'Dra. Ana',
        type: app_user.UserType.veterinarian,
        extraData: {'license_number': '12345'},
      );

      // VERIFICAÇÃO
      // 1. Ver se criou o auth user
      verify(mockGoTrueClient.signUp(email: email, password: any, data: anyNamed('data'))).called(1);

      // 2. Ver se inseriu na tabela 'profiles'
      verify(mockSupabaseClient.from('profiles')).called(1);
      
      // 3. Ver se inseriu na tabela 'veterinarians' (porque escolhemos tipo Veterinário)
      verify(mockSupabaseClient.from('veterinarians')).called(1);
      
      // 4. Garantir que NÃO inseriu em estudantes
      verifyNever(mockSupabaseClient.from('students'));
    });

    test('deve falhar se veterinário não tiver cédula', () async {
      // Tentar registar vet sem extraData
      expect(
        () => authService.register(
          email: 'vet@fail.com',
          password: 'pass',
          name: 'Vet Fail',
          type: app_user.UserType.veterinarian,
          extraData: null, // Falta a cédula
        ),
        throwsA(isA<Exception>()), // Deve lançar exceção "Cédula obrigatória"
      );
    });
  });
}