// lib/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';

// STUB - will be replaced in Task 9
final userProvider = AsyncNotifierProvider<UserNotifier, AppUser?>(UserNotifier.new);
class UserNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async => null;
}
