import '../entities/entities.dart';

class MyUser {
  final String userId; // ← final semua
  final String email;
  final String name;
  final bool hasActiveCart;

  const MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

  static const empty = MyUser(
    userId: '',
    email: '',
    name: '',
    hasActiveCart: false,
  );

  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;

  // ← tambah copyWith agar bisa "ubah" tanpa mutasi
  MyUser copyWith({
    String? userId,
    String? email,
    String? name,
    bool? hasActiveCart,
  }) {
    return MyUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      hasActiveCart: hasActiveCart ?? this.hasActiveCart,
    );
  }

  MyUserEntity toEntity() {
    return MyUserEntity(
      userId: userId,
      email: email,
      name: name,
      hasActiveCart: hasActiveCart,
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      hasActiveCart: entity.hasActiveCart,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email;

  @override
  int get hashCode => Object.hash(userId, email);

  @override
  String toString() {
    return 'MyUser: $userId, email: $email, name: $name, hasActiveCart: $hasActiveCart}';
  }
}
