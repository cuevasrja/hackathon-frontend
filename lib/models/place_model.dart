class Place {
  final int id;
  final String name;
  final String direction;
  final String city;
  final String country;
  final String type;
  final String? image;
  final int capacity;

  Place({
    required this.id,
    required this.name,
    required this.direction,
    required this.city,
    required this.country,
    required this.type,
    this.image,
    required this.capacity,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      direction: (json['direction'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      image: json['image'] as String?,
      // capacity puede venir como null desde la API, usar fallback a 0
      capacity: (json['capacity'] as int?) ?? 0,
    );
  }
}
