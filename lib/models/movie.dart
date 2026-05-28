class Movie {
  final String id;
  final String title;
  final String description;
  final String genre;
  final List<String> genres; // Daftar genre untuk ditampilkan sebagai chips
  final String year;
  final double rating;
  final int reviewsCount;
  final String posterUrl; // URL poster film

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    this.genres = const [],
    required this.year,
    required this.rating,
    required this.reviewsCount,
    required this.posterUrl,
  });
}
