import 'package:flutter/foundation.dart';

class AppConfig {
  // Set via --dart-define=BACKEND_URL at build/run time. Example:
  // flutter run -d chrome --dart-define=BACKEND_URL=https://api.example.com
  static final String _envBackend = const String.fromEnvironment('BACKEND_URL', defaultValue: '');
  
  static String get backendUrl {
    if (_envBackend != null && _envBackend.isNotEmpty) return _envBackend;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }
}
