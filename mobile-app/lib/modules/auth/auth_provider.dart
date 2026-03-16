import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medtrack_mobile/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
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
    if (token != null) {
      state = state.copyWith(isAuthenticated: true, token: token);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.login(email, password);
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.register(email, password);
      final token = data['token'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      state = state.copyWith(isLoading: false, isAuthenticated: true, token: token);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
