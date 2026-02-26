import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStoredEmail());
  }

  Future<void> _loadStoredEmail() async {
    final email = await ref.read(authProvider).getStoredEmail();
    if (mounted && email != null && _emailCtrl.text.isEmpty) {
      setState(() => _emailCtrl.text = email);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider).login(
            email: _emailCtrl.text.trim(),
            masterPassword: _passwordCtrl.text,
          );
      // Router handles navigation once auth state updates
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

  String _friendlyError(String e) {
    if (e.contains('INVALID_CREDENTIALS') || e.contains('401')) {
      return 'Correo o contraseña incorrectos';
    }
    if (e.contains('NetworkFailure') || e.contains('conexión')) {
      return 'Sin conexión. Verifica tu internet';
    }
    if (e.contains('RATE_LIMIT') || e.contains('429')) {
      return 'Demasiados intentos. Espera 15 minutos';
    }
    return 'Error al iniciar sesión. Intenta de nuevo';
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
                    const SizedBox(height: 48),
                    // Logo + title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Claveo',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text('Bienvenido', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa para acceder a tu vault cifrado',
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
                            hint: '••••••••••••',
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
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
                            onFieldSubmitted: (_) => _login(),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 32),
                    GradientButton(
                      label: 'Iniciar sesión',
                      onPressed: _loading ? null : _login,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.register),
                            child: const Text('Registrarte'),
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
