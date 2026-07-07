import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Mirrors `User` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class User with _$User {
  const factory User({
    required String? createdAt,
    required String? email,
    required String id,
    required bool? isAdmin,
    required String? lastLoginAt,
    required String name,
    required String? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
