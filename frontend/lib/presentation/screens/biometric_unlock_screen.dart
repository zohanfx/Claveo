import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class BiometricUnlockScreen extends ConsumerStatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  ConsumerState<BiometricUnlockScreen> createState() =>
      _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends ConsumerState<BiometricUnlockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _loading = false;
  bool _error = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4 || _loading) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length == 4) _validate();
  }

  void _onDelete() {
    if (_pin.isEmpty || _loading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _validate() async {
    setState(() => _loading = true);

    final success = await ref.read(authProvider).unlockWithPin(_pin);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      context.go(AppRoutes.vault);
    } else {
      await _shakeCtrl.forward(from: 0);
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBg, AppColors.darkSurface]
                : [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Vault bloqueado',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tu PIN para continuar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              // PIN dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? AppColors.error
                            : filled
                                ? AppColors.primary
                                : Colors.transparent,
                        border: Border.all(
                          color: _error
                              ? AppColors.error
                              : filled
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text(
                  'PIN incorrecto',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(flex: 2),
              // Numpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    _buildRow(['1', '2', '3'], theme, isDark),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6'], theme, isDark),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9'], theme, isDark),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72),
                        _buildDigitButton('0', theme, isDark),
                        _buildDeleteButton(theme),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loading ? null : _logout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Cerrar sesión'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits, ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d, theme, isDark)).toList(),
    );
  }

  Widget _buildDigitButton(String digit, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : () => _onDigit(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _onDelete,
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
