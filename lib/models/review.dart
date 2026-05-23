/// Model untuk review film
class Review {
  final String id;
  final String movieId;
  final String username;
  final int rating; // 1-5
  final String comment;
  final DateTime date;

  const Review({
    required this.id,
    required this.movieId,
    required this.username,
    required this.rating,
    required this.comment,
    required this.date,
  });

  /// Data dummy review
  static List<Review> get mockReviews => [
    Review(
      id: 'r1',
      movieId: '2', // Inception
      username: 'test',
      rating: 4,
      comment: 'bagus dan menarik',
      date: DateTime(2026, 4, 28),
    ),
    Review(
      id: 'r2',
      movieId: '5', // The Dark Knight
      username: 'cinephile',
      rating: 5,
      comment: 'Film terbaik sepanjang masa!',
      date: DateTime(2026, 5, 10),
    ),
    Review(
      id: 'r3',
      movieId: '1', // Forrest Gump
      username: 'moviefan',
      rating: 5,
      comment: 'Sangat mengharukan dan inspiratif',
      date: DateTime(2026, 5, 15),
    ),
    Review(
      id: 'r4',
      movieId: '3', // Interstellar
      username: 'spacelover',
      rating: 5,
      comment: 'Visual yang luar biasa!',
      date: DateTime(2026, 3, 20),
    ),
  ];
}
