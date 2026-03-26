import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  final String ip;
  final int port;

  const ServerConfig({required this.ip, required this.port});

  String get baseUrl => 'http://$ip:$port/api';

  ServerConfig copyWith({String? ip, int? port}) {
    return ServerConfig(
      ip: ip ?? this.ip,
      port: port ?? this.port,
    );
  }
}

final serverConfigProvider = StateNotifierProvider<ServerConfigNotifier, ServerConfig>((ref) {
  return ServerConfigNotifier();
});

class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  static const String _ipKey = 'server_ip';
  static const String _portKey = 'server_port';
  static const String _pinKey = 'admin_pin';
  static const String defaultIp = '10.0.2.51';
  static const int defaultPort = 5500;
  static const String defaultPin = '102424';

  ServerConfigNotifier() : super(const ServerConfig(ip: defaultIp, port: defaultPort)) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_ipKey) ?? defaultIp;
    final port = prefs.getInt(_portKey) ?? defaultPort;
    state = ServerConfig(ip: ip, port: port);
  }

  String _getLocalPin() {
    // This is synchronous if we already have prefs, otherwise it might be tricky.
    // However, for PIN verification, we can just read from SharedPreferences directly in the service.
    return defaultPin;
  }

  Future<void> updateConfig(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    await prefs.setInt(_portKey, port);
    state = ServerConfig(ip: ip, port: port);
  }

  Future<void> saveLocalPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<String> getLocalPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) ?? defaultPin;
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, defaultIp);
    await prefs.setInt(_portKey, defaultPort);
    await prefs.setString(_pinKey, defaultPin);
    state = const ServerConfig(ip: defaultIp, port: defaultPort);
  }
}
