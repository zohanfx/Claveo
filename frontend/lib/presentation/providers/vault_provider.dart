import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/vault_remote_datasource.dart';
import '../../data/repositories/vault_repository_impl.dart';
import '../../domain/entities/vault_entry_entity.dart';
import '../../domain/usecases/vault/delete_vault_entry_usecase.dart';
import '../../domain/usecases/vault/get_vault_usecase.dart';
import '../../domain/usecases/vault/save_vault_entry_usecase.dart';
import 'auth_provider.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final _vaultRemoteProvider = Provider<VaultRemoteDatasource>((ref) {
  return VaultRemoteDatasource(dioProvider);
});

final _vaultRepoProvider = Provider<VaultRepositoryImpl>((ref) {
  return VaultRepositoryImpl(remoteDatasource: ref.watch(_vaultRemoteProvider));
});

// ── Vault state ───────────────────────────────────────────────────────────────

@immutable
class VaultState {
  final List<VaultEntryEntity> entries;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedCategory;

  const VaultState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory = 'Todas',
  });

  List<VaultEntryEntity> get filteredEntries {
    var list = entries;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (e) =>
                e.servicio.toLowerCase().contains(q) ||
                e.usuario.toLowerCase().contains(q) ||
                e.url.toLowerCase().contains(q),
          )
          .toList();
    }

    if (selectedCategory != 'Todas') {
      list = list.where((e) => e.categoria == selectedCategory).toList();
    }

    return list;
  }

  VaultState copyWith({
    List<VaultEntryEntity>? entries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return VaultState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class VaultNotifier extends ChangeNotifier {
  final VaultRepositoryImpl _repo;
  final Ref _ref;

  VaultState _state = const VaultState();
  VaultState get state => _state;

  VaultNotifier(this._repo, this._ref);

  SecretKey? get _encKey => _ref.read(authProvider).encryptionKey;

  void _emit(VaultState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadVault() async {
    final key = _encKey;
    if (key == null) return;

    _emit(_state.copyWith(isLoading: true, error: null));
    try {
      final useCase = GetVaultUseCase(_repo);
      final entries = await useCase(encryptionKey: key);
      _emit(_state.copyWith(entries: entries, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createEntry(VaultEntryEntity entry) async {
    final key = _encKey;
    if (key == null) return;

    _emit(_state.copyWith(isLoading: true, error: null));
    try {
      final useCase = SaveVaultEntryUseCase(_repo);
      final created = await useCase.create(entry: entry, encryptionKey: key);
      _emit(_state.copyWith(
        entries: [created, ..._state.entries],
        isLoading: false,
      ));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateEntry(VaultEntryEntity entry) async {
    final key = _encKey;
    if (key == null) return;

    _emit(_state.copyWith(isLoading: true, error: null));
    try {
      final useCase = SaveVaultEntryUseCase(_repo);
      final updated = await useCase.update(entry: entry, encryptionKey: key);
      final updatedList = _state.entries.map((e) {
        return e.id == updated.id ? updated : e;
      }).toList();
      _emit(_state.copyWith(entries: updatedList, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    _emit(_state.copyWith(isLoading: true, error: null));
    try {
      final useCase = DeleteVaultEntryUseCase(_repo);
      await useCase(id: id);
      final updated = _state.entries.where((e) => e.id != id).toList();
      _emit(_state.copyWith(entries: updated, isLoading: false));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  void search(String query) {
    _emit(_state.copyWith(searchQuery: query, error: null));
  }

  void filterByCategory(String category) {
    _emit(_state.copyWith(selectedCategory: category, error: null));
  }

  void clearFilters() {
    _emit(_state.copyWith(searchQuery: '', selectedCategory: 'Todas'));
  }

  VaultEntryEntity? getById(String id) {
    try {
      return _state.entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final vaultProvider = ChangeNotifierProvider<VaultNotifier>((ref) {
  return VaultNotifier(ref.watch(_vaultRepoProvider), ref);
});
