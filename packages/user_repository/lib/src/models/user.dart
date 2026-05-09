import '../entities/entities.dart';

class MyUser {
  String userId;
  String email;
  String name;
  bool hasActiveCart;

  MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

  static final empty = MyUser(
    userId: '',
    email: '',
    name: '',
    hasActiveCart: false,
  );

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
