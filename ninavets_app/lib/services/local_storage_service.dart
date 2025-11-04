import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String _usersBoxName = 'usersBox';
  static Box<Map<String, dynamic>>? _usersBox;
  static bool _hiveInitialized = false;

  static Future<void> init() async {
    if (!_hiveInitialized) {
      await Hive.initFlutter();
      _hiveInitialized = true;
    }

    if (_usersBox == null || !_usersBox!.isOpen) {
      _usersBox = await Hive.openBox<Map<String, dynamic>>(_usersBoxName);
    }
  }

  static Future<Box<Map<String, dynamic>>> usersBox() async {
    if (_usersBox == null || !_usersBox!.isOpen) {
      await init();
    }
    return _usersBox!;
  }
}
