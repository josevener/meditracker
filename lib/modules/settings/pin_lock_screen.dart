import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/settings/pin_provider.dart';
import 'package:medtrack_mobile/modules/settings/biometric_provider.dart';
import 'package:medtrack_mobile/modules/settings/pin_provider.dart';
import 'package:medtrack_mobile/modules/settings/biometric_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final bool isSetupMode;
  final VoidCallback? onAuthenticated;

  const PinLockScreen({
    super.key,
    this.isSetupMode = false,
    this.onAuthenticated,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  String _firstEnteredPin = ''; // Used for setup confirmation
  bool _isConfirming = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isSetupMode) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (biometricEnabled) {
      // Delay slightly to allow the screen to render
      await Future.delayed(const Duration(milliseconds: 300));
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authenticated = await ref.read(biometricServiceProvider).authenticate();
    if (authenticated && mounted) {
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } 
      else {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleNumberPressed(int number) {
    if (_enteredPin.length < 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += number.toString();
        _errorMessage = '';
      });

      if (_enteredPin.length == 6) {
        _processPin();
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

  void _processPin() {
    if (widget.isSetupMode) {
      if (!_isConfirming) {
        // First entry during setup
        _firstEnteredPin = _enteredPin;
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _enteredPin = '';
            _isConfirming = true;
          });
        });
      } 
      else {
        // Confirmation entry
        if (_enteredPin == _firstEnteredPin) {
          ref.read(pinProvider.notifier).setPin(_enteredPin);
          if (widget.onAuthenticated != null) {
            widget.onAuthenticated!();
          } 
          // Note: If no onAuthenticated and no navigator (root), 
          // the parent (MedTrackApp) will rebuild via pinProvider state change.
        } 
        else {
          HapticFeedback.heavyImpact();
          setState(() {
            _enteredPin = '';
            _errorMessage = 'PINs do not match. Try again.';
          });
        }
      }
    } 
    else {
      // Unlock mode
      final savedPin = ref.read(pinProvider).value;
      if (_enteredPin == savedPin) {
      HapticFeedback.mediumImpact();
        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } 
        // Note: Rebuild handled by parent if root
      } 
      else {
        HapticFeedback.heavyImpact();
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetupMode 
        ? (_isConfirming ? 'Confirm PIN' : 'Create PIN') 
        : 'Enter PIN';

    return Scaffold(
      body: Stack(
        children: [
          // Geometric Background
          Positioned.fill(
            child: CustomPaint(
              painter: GeometricBackgroundPainter(
                color: Colors.pink.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.lock_outline, size: 48, color: Colors.pink),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a 6-digit PIN for extra security',
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
                // PIN Indicators
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
                const SizedBox(height: 60),
                // Linear Keypad
                _buildKeypad(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
            Consumer(
              builder: (context, ref, child) {
                final biometricEnabled = ref.watch(biometricEnabledProvider);
                if (!biometricEnabled || widget.isSetupMode) {
                  return const SizedBox(width: 80, height: 80);
                }
                return _buildIconButton(Icons.fingerprint, _authenticateWithBiometrics);
              },
            ),
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

class GeometricBackgroundPainter extends CustomPainter {
  final Color color;

  GeometricBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Fixed seed for consistent patterns

    for (int i = 0; i < 15; i++) {
      final centerX = random.nextDouble() * size.width;
      final centerY = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 100 + 50;
      final sides = random.nextInt(3) + 3; // 3 to 5 sides

      final path = Path();
      final angle = (2 * math.pi) / sides;

      for (int j = 0; j < sides; j++) {
        final x = centerX + radius * math.cos(j * angle);
        final y = centerY + radius * math.sin(j * angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
