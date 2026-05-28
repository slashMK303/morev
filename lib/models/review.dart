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

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      movieId: json['movie_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'username': username,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}
