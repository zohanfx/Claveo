import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/password_generator.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../providers/vault_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/password_strength_indicator.dart';

class AddPasswordScreen extends ConsumerStatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  ConsumerState<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends ConsumerState<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCategory = 'Otros';
  bool _showPassword = false;
  bool _loading = false;

  // Generator options
  int _genLength = AppConstants.defaultPasswordLength;
  bool _genUpper = AppConstants.defaultUppercase;
  bool _genLower = AppConstants.defaultLowercase;
  bool _genNumbers = AppConstants.defaultNumbers;
  bool _genSymbols = AppConstants.defaultSymbols;

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

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final entry = VaultEntryEntity(
        id: const Uuid().v4(),
        servicio: _serviceCtrl.text.trim(),
        usuario: _userCtrl.text.trim(),
        contrasena: _passwordCtrl.text,
        url: _urlCtrl.text.trim(),
        notas: _notesCtrl.text.trim(),
        categoria: _selectedCategory,
        fechaCreacion: now,
        fechaActualizacion: now,
      );

      await ref.read(vaultProvider).createEntry(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña guardada')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al guardar. Intenta de nuevo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _generatePassword() {
    final pwd = PasswordGenerator.generate(
      length: _genLength,
      includeUppercase: _genUpper,
      includeLowercase: _genLower,
      includeNumbers: _genNumbers,
      includeSymbols: _genSymbols,
    );
    setState(() => _passwordCtrl.text = pwd);
  }

  void _showGeneratorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GeneratorSheet(
        length: _genLength,
        upper: _genUpper,
        lower: _genLower,
        numbers: _genNumbers,
        symbols: _genSymbols,
        onApply: (l, u, lo, n, s) {
          setState(() {
            _genLength = l;
            _genUpper = u;
            _genLower = lo;
            _genNumbers = n;
            _genSymbols = s;
          });
          _generatePassword();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = PasswordGenerator.evaluateStrength(_passwordCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
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
            // Password field with generator
            Stack(
              alignment: Alignment.centerRight,
              children: [
                ClaveoTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña *',
                  hint: 'Tu contraseña',
                  obscureText: !_showPassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      IconButton(
                        icon: const Icon(Icons.casino_outlined),
                        onPressed: _showGeneratorSheet,
                        tooltip: 'Generar contraseña',
                      ),
                    ],
                  ),
                  validator: Validators.vaultPassword,
                ),
              ],
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
            // Category dropdown
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
            label: 'Guardar contraseña',
            onPressed: _loading ? null : _save,
            isLoading: _loading,
          ),
        ),
      ),
    );
  }
}

class _GeneratorSheet extends StatefulWidget {
  final int length;
  final bool upper;
  final bool lower;
  final bool numbers;
  final bool symbols;
  final void Function(int, bool, bool, bool, bool) onApply;

  const _GeneratorSheet({
    required this.length,
    required this.upper,
    required this.lower,
    required this.numbers,
    required this.symbols,
    required this.onApply,
  });

  @override
  State<_GeneratorSheet> createState() => _GeneratorSheetState();
}

class _GeneratorSheetState extends State<_GeneratorSheet> {
  late int _length;
  late bool _upper, _lower, _numbers, _symbols;
  String _preview = '';

  @override
  void initState() {
    super.initState();
    _length = widget.length;
    _upper = widget.upper;
    _lower = widget.lower;
    _numbers = widget.numbers;
    _symbols = widget.symbols;
    _updatePreview();
  }

  void _updatePreview() {
    setState(() {
      _preview = PasswordGenerator.generate(
        length: _length,
        includeUppercase: _upper,
        includeLowercase: _lower,
        includeNumbers: _numbers,
        includeSymbols: _symbols,
      );
    });
  }

  bool get _canGenerate => _upper || _lower || _numbers || _symbols;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generador de contraseñas',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _preview,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _canGenerate ? _updatePreview : null,
                    tooltip: 'Regenerar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Longitud: $_length caracteres',
              style: theme.textTheme.titleMedium,
            ),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 64,
              divisions: 56,
              onChanged: (v) {
                setState(() => _length = v.round());
                if (_canGenerate) _updatePreview();
              },
            ),
            const SizedBox(height: 8),
            ...[
              ('Mayúsculas (A-Z)', _upper, (v) => _upper = v),
              ('Minúsculas (a-z)', _lower, (v) => _lower = v),
              ('Números (0-9)', _numbers, (v) => _numbers = v),
              ('Símbolos (!@#\$)', _symbols, (v) => _symbols = v),
            ].map(
              (item) => SwitchListTile(
                title: Text(item.$1),
                value: item.$2,
                onChanged: (v) {
                  setState(() => item.$3(v));
                  if (_canGenerate) _updatePreview();
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canGenerate
                  ? () {
                      widget.onApply(
                        _length, _upper, _lower, _numbers, _symbols,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Usar esta contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
