class GenreApi {
  final int id;
  final String name;

  const GenreApi({required this.id, required this.name});

  factory GenreApi.fromJson(Map<String, dynamic> json) {
    return GenreApi(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
