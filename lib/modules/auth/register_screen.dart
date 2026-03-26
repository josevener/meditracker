import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/auth/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordController = TextEditingController();
  final _confirmPasswordFocus = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String _gender = 'Male';
  DateTime? _birthdate;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.pink.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.pink.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthdate) {
      if (!context.mounted) return;
      setState(() {
        _birthdate = picked;
      });
      // After selecting date, move focus to Address
      FocusScope.of(context).requestFocus(_addressFocus);
    }
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birthdate')),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            gender: _gender,
            birthdate: '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Success navigation: if we just became authenticated, pop the registration screen
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade600, const Color(0xFFFFF0F5)],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join MedTrack and stay healthy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            
                            return Column(
                              children: [
                                if (isNarrow) ...[
                                  TextFormField(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFocus),
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          focusNode: _firstNameFocus,
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFocus),
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            labelText: 'First Name',
                                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          focusNode: _lastNameFocus,
                                          textInputAction: TextInputAction.next,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (isNarrow) ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _gender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: const Icon(Icons.wc_outlined, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    items: ['Male', 'Female', 'Other'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: const TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() => _gender = newValue);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () => _selectDate(context),
                                    child: IgnorePointer(
                                      child: TextFormField(
                                        controller: TextEditingController(
                                          text: _birthdate == null 
                                            ? '' 
                                            : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}'
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          labelText: 'Birthdate',
                                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        validator: (_) => _birthdate == null ? 'Required' : null,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _gender,
                                          decoration: InputDecoration(
                                            labelText: 'Gender',
                                            prefixIcon: const Icon(Icons.wc_outlined, size: 20),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          items: ['Male', 'Female', 'Other'].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value, style: const TextStyle(fontSize: 14)),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            if (newValue != null) {
                                              setState(() => _gender = newValue);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: InkWell(
                                          onTap: () => _selectDate(context),
                                          child: IgnorePointer(
                                            child: TextFormField(
                                              controller: TextEditingController(
                                                text: _birthdate == null 
                                                  ? '' 
                                                  : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}'
                                              ),
                                              style: const TextStyle(fontSize: 14),
                                              decoration: InputDecoration(
                                                labelText: 'Birthdate',
                                                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                                ),
                                              ),
                                              validator: (_) => _birthdate == null ? 'Required' : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  focusNode: _addressFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Address (Optional)',
                                    prefixIcon: const Icon(Icons.home_outlined, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleRegister(),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (value.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocus,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleRegister(),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (value != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: authState.isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: _handleRegister,
                                          child: const Text(
                                            'REGISTER',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
