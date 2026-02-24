import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider).register(
            email: _emailCtrl.text.trim(),
            masterPassword: _passwordCtrl.text,
          );
      if (mounted) context.go(AppRoutes.vault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('EMAIL_EXISTS') || error.contains('409')) {
      return 'Este correo ya está registrado';
    }
    if (error.contains('NetworkFailure') || error.contains('conexión')) {
      return 'Sin conexión. Verifica tu internet';
    }
    return 'Error al crear cuenta. Intenta de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Back button
                    IconButton(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 32),
                    // Header
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Crear cuenta', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Tu contraseña maestra cifra todo. Ni nosotros podemos verla.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 36),
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ClaveoTextField(
                            controller: _emailCtrl,
                            label: 'Correo electrónico',
                            hint: 'tucorreo@ejemplo.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.email_outlined,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),
                          ClaveoTextField(
                            controller: _passwordCtrl,
                            label: 'Contraseña maestra',
                            hint: 'Mínimo 8 caracteres',
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                            ),
                            validator: Validators.masterPassword,
                          ),
                          const SizedBox(height: 16),
                          ClaveoTextField(
                            controller: _confirmCtrl,
                            label: 'Confirmar contraseña',
                            hint: 'Repite tu contraseña',
                            obscureText: !_showConfirm,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _showConfirm = !_showConfirm),
                            ),
                            validator: (v) =>
                                Validators.confirmPassword(v, _passwordCtrl.text),
                            onFieldSubmitted: (_) => _register(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Warning
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Recuerda tu contraseña maestra. Si la pierdes, '
                              'no podrás recuperar tu vault.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Crear cuenta',
                      onPressed: _loading ? null : _register,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text('Iniciar sesión'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
