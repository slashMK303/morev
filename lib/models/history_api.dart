class HistoryApi {
  final int movieId;
  final String title;
  final String poster;
  final String watchedAt;

  const HistoryApi({
    required this.movieId,
    required this.title,
    required this.poster,
    required this.watchedAt,
  });

  factory HistoryApi.fromJson(Map<String, dynamic> json) {
    return HistoryApi(
      movieId: json['movie_id'] is int
          ? json['movie_id']
          : int.tryParse(json['movie_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      watchedAt: json['watched_at']?.toString() ?? '',
    );
  }
}
