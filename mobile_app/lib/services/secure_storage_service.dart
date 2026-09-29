import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserSession = 'user_session';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveUserSession(Map<String, dynamic> user) async {
    await _storage.write(key: _keyUserSession, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserSession() async {
    final data = await _storage.read(key: _keyUserSession);
    if (data != null) {
      try {
        return jsonDecode(data);
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
