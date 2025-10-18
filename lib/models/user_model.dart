class User {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String? image;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      image: json['image'] as String?,
    );
  }
}
