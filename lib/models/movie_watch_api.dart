class MovieWatchApi {
  final String message;
  final String url;

  MovieWatchApi({
    required this.message,
    required this.url,
  });

  factory MovieWatchApi.fromJson(Map<String, dynamic> json) {
    return MovieWatchApi(
      message: json['message'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
