import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalPlatformStorage {
  const LocalPlatformStorage();

  Future<String?> read({
    required String key,
  }) async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    return await secureStorage.read(key: key);
  }

  Future<void> write({
    required String key,
    required String? value,
  }) async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.write(key: key, value: value);
  }

  Future<bool> containsKey({
    required String key,
  }) async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    return await secureStorage.containsKey(key: key);
  }

  Future<void> delete({
    required String key,
  }) async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.delete(key: key);
  }

  Future<void> deleteAll() async {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.deleteAll();
  }
}
