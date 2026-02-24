import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/vault_provider.dart';

class ViewPasswordScreen extends ConsumerStatefulWidget {
  final String entryId;

  const ViewPasswordScreen({super.key, required this.entryId});

  @override
  ConsumerState<ViewPasswordScreen> createState() => _ViewPasswordScreenState();
}

class _ViewPasswordScreenState extends ConsumerState<ViewPasswordScreen> {
  bool _showPassword = false;

  Future<void> _copyToClipboard(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copiado')),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text(
          '¿Seguro que quieres eliminar esta contraseña? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(vaultProvider).deleteEntry(widget.entryId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider).state;
    final entry = vault.entries.where((e) => e.id == widget.entryId).firstOrNull;
    final theme = Theme.of(context);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Entrada no encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.servicio),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editPasswordPath(entry.id)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
            color: AppColors.error,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Service header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.web_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.servicio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.categoria.isNotEmpty)
                        Text(
                          entry.categoria,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Data fields
          _DataField(
            label: 'Usuario / Correo',
            value: entry.usuario,
            onCopy: () => _copyToClipboard(entry.usuario, 'Usuario'),
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            value: entry.contrasena,
            visible: _showPassword,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onCopy: () => _copyToClipboard(entry.contrasena, 'Contraseña'),
          ),
          if (entry.url.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DataField(
              label: 'URL',
              value: entry.url,
              onCopy: () => _copyToClipboard(entry.url, 'URL'),
              icon: Icons.link_rounded,
            ),
          ],
          if (entry.notas.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DataField(
              label: 'Notas',
              value: entry.notas,
              icon: Icons.notes_rounded,
            ),
          ],
          const SizedBox(height: 24),
          // Timestamps
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),
          _TimestampRow(
            label: 'Creado',
            date: entry.fechaCreacion,
          ),
          const SizedBox(height: 6),
          _TimestampRow(
            label: 'Actualizado',
            date: entry.fechaActualizacion,
          ),
        ],
      ),
    );
  }
}

class _DataField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final IconData icon;

  const _DataField({
    required this.label,
    required this.value,
    required this.icon,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: onCopy,
              tooltip: 'Copiar',
            ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String value;
  final bool visible;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  const _PasswordField({
    required this.value,
    required this.visible,
    required this.onToggle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTRASEÑA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visible ? value : '•' * value.length.clamp(8, 20),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: visible ? 'monospace' : null,
                    letterSpacing: visible ? 1.5 : 4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: onToggle,
            tooltip: visible ? 'Ocultar' : 'Mostrar',
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: onCopy,
            tooltip: 'Copiar contraseña',
          ),
        ],
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final String label;
  final DateTime date;

  const _TimestampRow({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          _format(date),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _format(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}
