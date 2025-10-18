class Community {
  final int id;
  final String name;

  Community({
    required this.id,
    required this.name,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}
