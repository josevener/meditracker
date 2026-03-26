import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medtrack_mobile/core/api/api_client.dart';

final authServiceProvider = Provider((ref) => AuthService(ref.watch(apiClientProvider)));

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? email;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.email,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? email,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      email: email ?? this.email,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true, token: token, email: email);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.login(email, password);
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_email', email);
      
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token, email: email);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String birthdate,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        birthdate: birthdate,
        address: address,
      );
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_email', email);
      
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token, email: email);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        return data['error'] ?? data['message'] ?? e.message ?? e.toString();
      }
      return e.message ?? e.toString();
    }
    String msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return msg;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
