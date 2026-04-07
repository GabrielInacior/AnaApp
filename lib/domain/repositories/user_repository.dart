// lib/domain/repositories/user_repository.dart
import '../entities/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser?> getUser();
  Future<void> saveUser(AppUser user);
  Future<void> updateUserName(String name);
}
