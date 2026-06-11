import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final String targetRoute;
  const LockScreen({super.key, required this.targetRoute});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String? _storedPin;
  bool _biometricsEnabled = false;
  bool _canUseBiometrics = false;
  bool _isChecking = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final stored = await BiometricService.instance.getPinCode();
    final bioEnabled = await BiometricService.instance.isBiometricEnabled();
    final canBio = await BiometricService.instance.canUseBiometrics();

    setState(() {
      _storedPin = stored;
      _biometricsEnabled = bioEnabled;
      _canUseBiometrics = canBio;
      _isChecking = false;
    });

    if (bioEnabled && canBio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometric();
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    final success = await BiometricService.instance.authenticate();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, widget.targetRoute);
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_enteredPin == _storedPin) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.pushReplacementNamed(context, widget.targetRoute);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isChecking) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brand),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Lock Status & Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 30,
              ),
            ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              'Enter PIN',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              _hasError ? 'Incorrect PIN, try again' : 'Access your Velo ledger',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _hasError ? AppColors.error : colors.textSecondary,
                fontWeight: _hasError ? FontWeight.w600 : null,
              ),
            ),
            const SizedBox(height: 30),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? AppColors.error
                        : filled
                            ? AppColors.brand
                            : colors.border,
                    border: Border.all(
                      color: _hasError
                          ? AppColors.error
                          : filled
                              ? AppColors.brand
                              : colors.textTertiary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ).animate(target: _hasError ? 1 : 0)
             .shakeX(duration: 400.ms, hz: 6, curve: Curves.bounceIn),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _keypadButton('1'),
                      _keypadButton('2'),
                      _keypadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _keypadButton('4'),
                      _keypadButton('5'),
                      _keypadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _keypadButton('7'),
                      _keypadButton('8'),
                      _keypadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left utility button: Biometric Trigger
                      _biometricButton(colors),
                      _keypadButton('0'),
                      // Right utility button: Backspace
                      _deleteButton(colors),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _keypadButton(String digit) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
            color: colors.surfaceAlt.withValues(alpha: 0.3),
          ),
          child: Center(
            child: Text(
              digit,
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _biometricButton(AppColorSet colors) {
    final active = _biometricsEnabled && _canUseBiometrics;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active ? _authenticateBiometric : null,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(
              Icons.fingerprint_rounded,
              color: active ? AppColors.brand : Colors.transparent,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteButton(AppColorSet colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onDelete,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: colors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
