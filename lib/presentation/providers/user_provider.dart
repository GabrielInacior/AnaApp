// lib/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import 'repository_providers.dart';

final userProvider = AsyncNotifierProvider<UserNotifier, AppUser?>(UserNotifier.new);

class UserNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final repo = ref.read(userRepositoryProvider);
    return repo.getUser();
  }

  Future<void> saveUser(AppUser user) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.saveUser(user);
    state = AsyncData(user);
  }

  Future<void> updateName(String name) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateUserName(name);
    state = state.whenData((u) => u != null
        ? AppUser(id: u.id, name: name, createdAt: u.createdAt)
        : null);
  }
}
