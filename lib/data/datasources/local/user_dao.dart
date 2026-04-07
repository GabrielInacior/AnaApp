// lib/data/datasources/local/user_dao.dart
import '../../../domain/entities/app_user.dart';
import '../../models/app_user_model.dart';
import 'database_helper.dart';

class UserDAO {
  final DatabaseHelper _helper;
  UserDAO(this._helper);

  Future<AppUser?> getUser() async {
    final db = await _helper.database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return AppUserModel.fromMap(maps.first).toEntity();
  }

  Future<void> saveUser(AppUser user) async {
    final db = await _helper.database;
    await db.insert('users', AppUserModel.fromEntity(user).toMap());
  }

  Future<void> updateName(String name) async {
    final db = await _helper.database;
    await db.update('users', {'name': name});
  }
}
