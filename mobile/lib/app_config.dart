import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envBackend = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  
  static String get backendUrl {
    // We only need to check if it's not empty!
    if (_envBackend.isNotEmpty) return _envBackend;
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }
}
