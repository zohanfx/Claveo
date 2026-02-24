import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/vault_provider.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/vault_entry_card.dart';

class VaultDashboardScreen extends ConsumerStatefulWidget {
  const VaultDashboardScreen({super.key});

  @override
  ConsumerState<VaultDashboardScreen> createState() =>
      _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends ConsumerState<VaultDashboardScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider).loadVault();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(vaultProvider).loadVault();
  }

  @override
  Widget build(BuildContext context) {
    final vaultNotifier = ref.watch(vaultProvider);
    final vault = vaultNotifier.state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi Vault', style: theme.textTheme.headlineLarge),
                        if (vault.entries.isNotEmpty)
                          Text(
                            '${vault.entries.length} contraseña${vault.entries.length != 1 ? 's' : ''}',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.settings_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : AppColors.inputBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref.read(vaultProvider).search(v),
                decoration: InputDecoration(
                  hintText: 'Buscar por servicio o usuario...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: vault.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(vaultProvider).search('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category filter
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = AppConstants.categories[i];
                  return CategoryFilterChip(
                    label: cat,
                    selected: vault.selectedCategory == cat,
                    onTap: () => ref.read(vaultProvider).filterByCategory(cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Content
            Expanded(
              child: vault.isLoading && vault.entries.isEmpty
                  ? const VaultLoadingSkeleton()
                  : vault.filteredEntries.isEmpty
                      ? _buildEmpty(vault.searchQuery, vault.selectedCategory)
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: vault.filteredEntries.length,
                            itemBuilder: (_, i) {
                              final entry = vault.filteredEntries[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: VaultEntryCard(
                                  entry: entry,
                                  onTap: () => context.push(
                                    AppRoutes.viewPasswordPath(entry.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addPassword),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva clave',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmpty(String query, String category) {
    if (query.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        subtitle: 'No encontramos nada para "$query"',
        actionLabel: 'Limpiar búsqueda',
        onAction: () {
          _searchCtrl.clear();
          ref.read(vaultProvider).clearFilters();
        },
      );
    }
    if (category != 'Todas') {
      return EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Sin entradas',
        subtitle: 'No tienes contraseñas en "$category"',
        actionLabel: 'Ver todas',
        onAction: () => ref.read(vaultProvider).filterByCategory('Todas'),
      );
    }
    return EmptyState(
      icon: Icons.lock_open_outlined,
      title: 'Vault vacío',
      subtitle: 'Agrega tu primera contraseña para empezar',
      actionLabel: 'Agregar contraseña',
      onAction: () => context.push(AppRoutes.addPassword),
    );
  }
}
