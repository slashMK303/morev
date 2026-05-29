import 'movie.dart';
import 'genre_api.dart';

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
  final List<GenreApi> genres;

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
    required this.genres,
  });

  factory MovieApi.fromJson(Map<String, dynamic> json) {
    var genreList = <GenreApi>[];
    if (json['genres'] is List) {
      genreList = (json['genres'] as List)
          .map((g) => GenreApi.fromJson(Map<String, dynamic>.from(g)))
          .toList();
    }

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
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      viewers: json['viewers'] ?? 0,
      isWatchlist: json['is_watchlist'] ?? false,
      genres: genreList,
    );
  }

  // Map API model to UI Movie model used in app
  Movie toMovie() {
    return Movie(
      id: id.toString(),
      title: title,
      description: description,
      genre: genres.isNotEmpty ? genres.first.name : '',
      genres: genres.map((g) => g.name).toList(),
      year: releaseYear.toString(),
      rating: rating,
      reviewsCount: viewers,
      posterUrl: poster,
    );
  }
}
