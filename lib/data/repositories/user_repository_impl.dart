// lib/data/repositories/user_repository_impl.dart
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_dao.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDAO _dao;
  UserRepositoryImpl(this._dao);

  @override
  Future<AppUser?> getUser() => _dao.getUser();

  @override
  Future<void> saveUser(AppUser user) => _dao.saveUser(user);

  @override
  Future<void> updateUserName(String name) => _dao.updateName(name);
}
