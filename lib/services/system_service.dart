import 'package:medtrack_mobile/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemService {
  final ApiClient _apiClient;

  SystemService(this._apiClient);

  Future<bool> verifyAdminPin(String pin) async {
    try {
      final response = await _apiClient.dio.post('/system/verify-pin', data: {
        'pin': pin,
      }).timeout(const Duration(seconds: 3));
      
      final success = response.data['success'] == true;
      if (success) {
        // Sync to local cache on success
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_pin', pin);
      }
      return success;
    } catch (e) {
      // Fallback to local check if remote fails
      final prefs = await SharedPreferences.getInstance();
      final localPin = prefs.getString('admin_pin') ?? '102424';
      return pin == localPin;
    }
  }

  Future<bool> updateAdminPin(String pin) async {
    try {
      final response = await _apiClient.dio.post('/system/update-pin', data: {
        'pin': pin,
      });
      final success = response.data['success'] == true;
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_pin', pin);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getServerConfig() async {
    try {
      final response = await _apiClient.dio.get('/system/config');
      if (response.data['config'] != null) {
        return Map<String, dynamic>.from(response.data['config']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateServerConfig(String ip, int port) async {
    try {
      final response = await _apiClient.dio.post('/system/update-config', data: {
        'server_ip': ip,
        'server_port': port,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
