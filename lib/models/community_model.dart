class Community {
  final int id;
  final String name;
  final String description;
  final String? image;
  final int? categoryId;

  Community({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    this.categoryId,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      image: json['image'] as String?,
      categoryId: json['categoryId'] as int?,
    );
  }
}
