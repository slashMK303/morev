class WatchlistApi {
  final int id;
  final int movieId;
  final String title;
  final String poster;
  final String releaseYear;

  const WatchlistApi({
    required this.id,
    required this.movieId,
    required this.title,
    required this.poster,
    required this.releaseYear,
  });

  factory WatchlistApi.fromJson(Map<String, dynamic> json) {
    return WatchlistApi(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      movieId: json['movie_id'] is int
          ? json['movie_id']
          : int.tryParse(json['movie_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      releaseYear: json['release_year']?.toString() ?? '',
    );
  }
}
