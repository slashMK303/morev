import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../models/movie_api.dart';
import '../models/movie_watch_api.dart';
import '../services/movie_service.dart';
import '../services/review_service.dart';
import '../services/watchlist_service.dart';
import '../state/app_state.dart';
import '../storage/token_storage.dart';
import '../storage/review_storage.dart';
import '../storage/view_storage.dart';
import '../utils/api_error_handler.dart';
import '../theme/app_theme.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final AppState appState;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    required this.appState,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  int _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<Review> _reviews = [];
  Movie? _movie;
  bool _loadingDetail = false;
  final ReviewService _reviewService = ReviewService();
  final MovieService _movieService = MovieService();
  final WatchlistService _watchlistService = WatchlistService();
  final TokenStorage _tokenStorage = TokenStorage();
  final ReviewStorage _reviewStorage = ReviewStorage();

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    // Ambil review untuk film ini
    _loadLocalReviews();
    _loadMovieDetail();
    widget.appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChange);
    _commentController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocalReviews() async {
    final reviews = await _reviewStorage.loadReviews();
    if (!mounted) return;
    setState(() {
      _reviews = reviews.where((r) => r.movieId == widget.movie.id).toList();
    });
  }

  Future<void> _loadMovieDetail() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return;

    final movieId = int.tryParse(widget.movie.id);
    if (movieId == null) return;

    setState(() {
      _loadingDetail = true;
    });

    try {
      final resp = await _movieService.getMovieDetail(
        token: token,
        movieId: movieId,
      );

      if (resp.statusCode == 200) {
        final data = Map<String, dynamic>.from(resp.data['data']);
        final apiMovie = MovieApi.fromJson(data);

        final reviewsData = data['reviews'];
        final serverReviews = <Review>[];
        if (reviewsData is List) {
          for (final item in reviewsData) {
            if (item is Map<String, dynamic>) {
              serverReviews.add(
                Review(
                  id: item['id']?.toString() ?? '',
                  movieId: widget.movie.id,
                  username: 'Anonim',
                  rating: item['rating'] is int
                      ? item['rating']
                      : int.tryParse(item['rating']?.toString() ?? '0') ?? 0,
                  comment: item['comment']?.toString() ?? '',
                  date:
                      DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                      DateTime.now(),
                ),
              );
            }
          }
        }

        final localReviews = await _reviewStorage.loadReviews();
        final localForMovie = localReviews
            .where((r) => r.movieId == widget.movie.id)
            .toList();
        final mergedReviews = <Review>[...localForMovie];
        for (final review in serverReviews) {
          final duplicate = mergedReviews.any(
            (item) =>
                item.comment == review.comment && item.rating == review.rating,
          );
          if (!duplicate) {
            mergedReviews.add(review);
          }
        }

        if (!mounted) return;
        setState(() {
          _movie = apiMovie.toMovie();
          _reviews = mergedReviews;
        });
      }
    } catch (_) {
      // ignore detail load failures; fallback to existing data
    } finally {
      if (mounted) {
        setState(() {
          _loadingDetail = false;
        });
      }
    }
  }

  Future<void> _toggleWatchlist() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final movieId = int.tryParse(_movie?.id ?? widget.movie.id);
    if (movieId == null) return;

    final watchId = _movie?.id ?? widget.movie.id;
    final isWatchlisted = widget.appState.isWatchlisted(watchId);

    try {
      if (isWatchlisted) {
        await _watchlistService.removeWatchlist(token: token, movieId: movieId);
      } else {
        await _watchlistService.addWatchlist(token: token, movieId: movieId);
      }
      widget.appState.toggleWatchlist(watchId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(e, fallback: 'Gagal memperbarui watchlist'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Hitung distribusi rating (1-5) dari daftar review
  Map<int, int> _getRatingDistribution() {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      dist[review.rating] = (dist[review.rating] ?? 0) + 1;
    }
    return dist;
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1F222B),
          content: Text(
            'Pilih rating terlebih dahulu!',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token login tidak ditemukan. Silakan login ulang.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final movieId = int.tryParse(_movie?.id ?? widget.movie.id);
    if (movieId == null) return;

    try {
      await _reviewService.createReview(
        token: token,
        movieId: movieId,
        rating: _userRating,
        comment: _commentController.text.trim(),
      );

      final newReview = Review(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        movieId: _movie?.id ?? widget.movie.id,
        username: widget.appState.currentUser?.username ?? 'Anonim',
        rating: _userRating,
        comment: _commentController.text.trim(),
        date: DateTime.now(),
      );

      await _reviewStorage.saveReview(newReview);

      if (!mounted) return;
      setState(() {
        _reviews.insert(0, newReview);
        _userRating = 0;
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1F222B),
          content: Text(
            'Review berhasil dikirim!',
            style: TextStyle(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyApiError(e, fallback: 'Gagal kirim review')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _watchMovie() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return;

    final movieId = int.tryParse(_movie?.id ?? widget.movie.id);
    if (movieId == null) return;

    try {
      final resp = await _movieService.watchMovie(
        token: token,
        movieId: movieId,
      );
      if (resp.statusCode == 200 && mounted) {
        widget.appState.incrementViewCount();
        await ViewStorage().saveCount(widget.appState.viewCount);
      }
    } catch (_) {
      // ignore watch history failures
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movie ?? widget.movie;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Film',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Banner / Poster film
            _buildPosterBanner(),
            // Info film
            _buildMovieInfoCard(movie),
            const SizedBox(height: 16),
            // Tambah Review
            _buildAddReviewCard(),
            const SizedBox(height: 16),
            // Daftar Review
            _buildReviewsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Banner poster film di atas
  Widget _buildPosterBanner() {
    final movie = _movie ?? widget.movie;
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1E212E),
                  child: const Center(
                    child: Icon(
                      Icons.movie_rounded,
                      size: 64,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loadingDetail)
            const Positioned(
              right: 12,
              bottom: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Card info film (judul, tahun, genre, sinopsis, statistik rating, tombol)
  Widget _buildMovieInfoCard(Movie movie) {
    final isWatchlisted = widget.appState.isWatchlisted(movie.id);
    final genres = movie.genres.isNotEmpty ? movie.genres : [movie.genre];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E212E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul film
          Text(
            movie.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Tahun
          Text(
            movie.year,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: 12),
          // Genre chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGold, width: 1),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Deskripsi
          Text(
            movie.description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Statistik Rating
          const Text(
            'Statistik Rating',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildRatingStats(),
          const SizedBox(height: 20),
          // Tombol Watchlist & Lihat Film
          Row(
            children: [
              // Watchlist button
              Expanded(
                child: InkWell(
                  onTap: _toggleWatchlist,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isWatchlisted
                          ? const Color(0xFF2C303E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isWatchlisted
                            ? Colors.transparent
                            : const Color(0xFF2C303E),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isWatchlisted
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: isWatchlisted
                              ? AppTheme.primaryGold
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isWatchlisted ? 'Tersimpan' : 'Watchlist',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isWatchlisted
                                ? AppTheme.primaryGold
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Lihat Film button
              Expanded(
                child: InkWell(
                  onTap: () {
                    _watchMovie();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1F222B),
                        content: Text(
                          'Memutar ${movie.title}...',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: Colors.black.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lihat Film',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget statistik rating (bar chart 1-5 bintang)
  Widget _buildRatingStats() {
    final dist = _getRatingDistribution();
    final maxCount = dist.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index;
        final count = dist[star] ?? 0;
        final ratio = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppTheme.primaryGold,
                size: 16,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 14,
                child: Text(
                  '$star',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: const Color(0xFF2C303E),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGold,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Card tambah review (rating bintang + komentar + tombol kirim)
  Widget _buildAddReviewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E212E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Review',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Label Rating
          const Text(
            'Rating',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Bintang rating selector
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _userRating = starIndex;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    starIndex <= _userRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: starIndex <= _userRating
                        ? AppTheme.primaryGold
                        : AppTheme.textMuted,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Label Komentar
          const Text(
            'Komentar (opsional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Text field komentar
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tulis pendapat kamu tentang film ini...',
              hintStyle: const TextStyle(
                color: Color(0xFF5E6577),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppTheme.inputGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2C303E),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2C303E),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryGold,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          // Tombol Kirim Review
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Kirim Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card daftar review yang sudah ada
  Widget _buildReviewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E212E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review (${_reviews.length})',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada review untuk film ini.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(_reviews.length, (index) {
              final review = _reviews[index];
              return _buildReviewItem(
                review,
                isLast: index == _reviews.length - 1,
              );
            }),
        ],
      ),
    );
  }

  /// Item review individu
  Widget _buildReviewItem(Review review, {bool isLast = false}) {
    // Format tanggal
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dateStr =
        '${review.date.day} ${months[review.date.month]} ${review.date.year}';

    // Inisial dari username
    final initial = review.username.isNotEmpty
        ? review.username[0].toUpperCase()
        : '?';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar inisial
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2C303E),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Konten review
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  review.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                // Rating bintang & tanggal
                Row(
                  children: [
                    // Bintang kecil
                    ...List.generate(5, (i) {
                      return Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 14,
                        color: i < review.rating
                            ? AppTheme.primaryGold
                            : AppTheme.textMuted,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.comment,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
