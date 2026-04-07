// lib/data/models/app_user_model.dart
import '../../domain/entities/app_user.dart';

class AppUserModel {
  final String id;
  final String name;
  final String createdAt;

  const AppUserModel({required this.id, required this.name, required this.createdAt});

  factory AppUserModel.fromMap(Map<String, dynamic> map) => AppUserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt,
      };

  AppUser toEntity() => AppUser(
        id: id,
        name: name,
        createdAt: DateTime.parse(createdAt),
      );

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
        id: user.id,
        name: user.name,
        createdAt: user.createdAt.toIso8601String(),
      );
}
