import 'movie.dart';

class MovieApi {
  final int id;
  final String title;
  final String description;
  final int releaseYear;
  final String poster;
  final String backdrop;
  final String movieUrl;
  final double rating;
  final int viewers;
  final bool isWatchlist;

  MovieApi({
    required this.id,
    required this.title,
    required this.description,
    required this.releaseYear,
    required this.poster,
    required this.backdrop,
    required this.movieUrl,
    required this.rating,
    required this.viewers,
    required this.isWatchlist,
  });

  factory MovieApi.fromJson(Map<String, dynamic> json) {
    return MovieApi(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      releaseYear: json['release_year'] is int
          ? json['release_year']
          : int.tryParse(json['release_year']?.toString() ?? '0') ?? 0,
      poster: json['poster'] ?? '',
      backdrop: json['backdrop'] ?? '',
      movieUrl: json['movie_url'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      viewers: json['viewers'] ?? 0,
      isWatchlist: json['is_watchlist'] ?? false,
    );
  }

  // Map API model to UI Movie model used in app
  Movie toMovie() {
    return Movie(
      id: id.toString(),
      title: title,
      description: description,
      genre: '',
      genres: const [],
      year: releaseYear.toString(),
      rating: rating,
      reviewsCount: viewers,
      posterUrl: poster,
    );
  }
}
