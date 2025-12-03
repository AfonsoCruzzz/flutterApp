import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ninavets_app/models/user.dart';
import 'package:ninavets_app/services/auth_service.dart';
import 'package:ninavets_app/services/local_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final Directory baseDir = Directory.systemTemp.createTempSync();

  @override
  Future<String?> getApplicationDocumentsPath() async => baseDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => baseDir.path;

  @override
  Future<String?> getTemporaryPath() async => baseDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProvider();

  group('AuthService Hive persistence', () {
    setUp(() async {
      final box = await LocalStorageService.usersBox();
      await box.clear();
    });

    test('registers and logs in after restart', () async {
      final auth = AuthService();
      const email = 'test@example.com';
      const password = '123456';

      await auth.register(
        email,
        password,
        'Tester',
        UserType.client,
        null,
      );

      final user = await AuthService.login(email, password);
      expect(user, isNotNull);

      final box = await LocalStorageService.usersBox();
      await box.close();

      await LocalStorageService.init();

      final userAfterRestart = await AuthService.login(email, password);
      expect(userAfterRestart, isNotNull);
    });
  });
}
