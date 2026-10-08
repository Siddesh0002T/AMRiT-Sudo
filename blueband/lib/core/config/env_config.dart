import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig {
  static final EnvConfig instance = EnvConfig._();
  EnvConfig._();

  String _geminiApiKey = '';
  // Default server URL pointing to local PHP/MySQL server on Laptop Hotspot
  String _serverBaseUrl = 'http://192.168.137.1:8000/api.php';

  String get geminiApiKey => _geminiApiKey;
  String get serverBaseUrl => _serverBaseUrl;

  bool get hasGeminiApiKey => _geminiApiKey.trim().isNotEmpty;

  Future<void> init() async {
    // 1. Try loading from SharedPreferences overrides first
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGeminiKey = prefs.getString('custom_gemini_api_key');
      final savedServerUrl = prefs.getString('custom_server_base_url');
      if (savedGeminiKey != null && savedGeminiKey.trim().isNotEmpty) {
        _geminiApiKey = savedGeminiKey.trim();
      }
      if (savedServerUrl != null && savedServerUrl.trim().isNotEmpty) {
        _serverBaseUrl = savedServerUrl.trim();
      }
    } catch (_) {}

    // 2. Read from assets/.env if available
    try {
      final envString = await rootBundle.loadString('.env');
      _parseEnv(envString);
    } catch (e) {
      debugPrint('Note: .env file in rootBundle not found or empty: $e');
    }
  }

  void _parseEnv(String content) {
    final lines = content.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", '');
        if (key == 'GEMINI_API_KEY' && _geminiApiKey.isEmpty && value.isNotEmpty) {
          _geminiApiKey = value;
        } else if ((key == 'SERVER_BASE_URL' || key == 'API_BASE_URL') && value.isNotEmpty) {
          _serverBaseUrl = value;
        }
      }
    }
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_gemini_api_key', _geminiApiKey);
    } catch (_) {}
  }

  Future<void> setServerBaseUrl(String url) async {
    var clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    _serverBaseUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_server_base_url', _serverBaseUrl);
    } catch (_) {}
  }
}
