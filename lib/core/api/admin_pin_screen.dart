import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/core/api/admin_pin_provider.dart';

class AdminPinScreen extends ConsumerStatefulWidget {
  final Widget navigateTo;

  const AdminPinScreen({super.key, required this.navigateTo});

  @override
  ConsumerState<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends ConsumerState<AdminPinScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isLoading = false;

  void _handleNumberPressed(int number) {
    if (_enteredPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += number.toString();
        _errorMessage = '';
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    final success = await ref.read(systemServiceProvider).verifyAdminPin(_enteredPin);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.navigateTo),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Invalid Admin PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Authentication'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.pink),
        titleTextStyle: const TextStyle(
          color: Colors.pink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.security, size: 64, color: Colors.pink),
            const SizedBox(height: 24),
            const Text(
              'Enter Configuration PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access to server settings is restricted',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            const Spacer(),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade200, width: 1.5),
                      color: isFilled ? Colors.pink : Colors.transparent,
                    ),
                  );
                }),
              ),
            const SizedBox(height: 40),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(1),
            _buildKey(2),
            _buildKey(3),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(4),
            _buildKey(5),
            _buildKey(6),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(7),
            _buildKey(8),
            _buildKey(9),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _buildKey(0),
            _buildIconButton(Icons.backspace_outlined, _handleBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(int number) {
    return InkWell(
      onTap: () => _handleNumberPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.pink.shade100, width: 1),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: Icon(icon, size: 28, color: Colors.pink.shade300),
        ),
      ),
    );
  }
}
