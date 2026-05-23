class MyUserEntity {
  final String userId;
  final String email;
  final String name;
  final bool hasActiveCart;

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.hasActiveCart,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'hasActiveCart': hasActiveCart,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'] as String? ?? '',
      email: doc['email'] as String? ?? '',
      name: doc['name'] as String? ?? '',
      hasActiveCart: doc['hasActiveCart'] as bool? ?? false,
    );
  }
}

// 3
