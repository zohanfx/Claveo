import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_generator.dart';
import '../../core/utils/validators.dart';
import '../providers/vault_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/password_strength_indicator.dart';

class EditPasswordScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EditPasswordScreen({super.key, required this.entryId});

  @override
  ConsumerState<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends ConsumerState<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCategory = 'Otros';
  bool _showPassword = false;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final entry = ref.read(vaultProvider).state.entries
          .where((e) => e.id == widget.entryId)
          .firstOrNull;
      if (entry != null) {
        _serviceCtrl.text = entry.servicio;
        _userCtrl.text = entry.usuario;
        _passwordCtrl.text = entry.contrasena;
        _urlCtrl.text = entry.url;
        _notesCtrl.text = entry.notas;
        _selectedCategory = entry.categoria;
      }
    }
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final original = ref
        .read(vaultProvider)
        .state
        .entries
        .where((e) => e.id == widget.entryId)
        .firstOrNull;
    if (original == null) return;

    setState(() => _loading = true);
    try {
      final updated = original.copyWith(
        servicio: _serviceCtrl.text.trim(),
        usuario: _userCtrl.text.trim(),
        contrasena: _passwordCtrl.text,
        url: _urlCtrl.text.trim(),
        notas: _notesCtrl.text.trim(),
        categoria: _selectedCategory,
        fechaActualizacion: DateTime.now(),
      );

      await ref.read(vaultProvider).updateEntry(updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al actualizar. Intenta de nuevo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordGenerator.evaluateStrength(_passwordCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            ClaveoTextField(
              controller: _serviceCtrl,
              label: 'Servicio *',
              hint: 'Ej: Netflix, Gmail, BBVA...',
              prefixIcon: Icons.web_outlined,
              textInputAction: TextInputAction.next,
              validator: Validators.serviceName,
            ),
            const SizedBox(height: 14),
            ClaveoTextField(
              controller: _userCtrl,
              label: 'Usuario o correo',
              hint: 'Ej: miusuario@email.com',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            ClaveoTextField(
              controller: _passwordCtrl,
              label: 'Contraseña *',
              hint: 'Tu contraseña',
              obscureText: !_showPassword,
              prefixIcon: Icons.lock_outline_rounded,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              validator: Validators.vaultPassword,
            ),
            const SizedBox(height: 8),
            if (_passwordCtrl.text.isNotEmpty)
              PasswordStrengthIndicator(strength: strength),
            const SizedBox(height: 14),
            ClaveoTextField(
              controller: _urlCtrl,
              label: 'URL (opcional)',
              hint: 'https://ejemplo.com',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              validator: Validators.url,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              items: AppConstants.categoriesWithoutAll
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 14),
            ClaveoTextField(
              controller: _notesCtrl,
              label: 'Notas (opcional)',
              hint: 'Información adicional...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: GradientButton(
            label: 'Guardar cambios',
            onPressed: _loading ? null : _save,
            isLoading: _loading,
          ),
        ),
      ),
    );
  }
}
