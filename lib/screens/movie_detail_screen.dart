import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../state/app_state.dart';
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
  late List<Review> _reviews;

  @override
  void initState() {
    super.initState();
    // Ambil review untuk film ini
    _reviews = Review.mockReviews
        .where((r) => r.movieId == widget.movie.id)
        .toList();
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

  /// Hitung distribusi rating (1-5) dari daftar review
  Map<int, int> _getRatingDistribution() {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      dist[review.rating] = (dist[review.rating] ?? 0) + 1;
    }
    return dist;
  }

  void _submitReview() {
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

    final newReview = Review(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      movieId: widget.movie.id,
      username: widget.appState.currentUser?.username ?? 'Anonim',
      rating: _userRating,
      comment: _commentController.text.trim(),
      date: DateTime.now(),
    );

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
  }

  @override
  Widget build(BuildContext context) {
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
            _buildMovieInfoCard(),
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
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.network(
        widget.movie.posterUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
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
    );
  }

  /// Card info film (judul, tahun, genre, sinopsis, statistik rating, tombol)
  Widget _buildMovieInfoCard() {
    final isWatchlisted = widget.appState.isWatchlisted(widget.movie.id);
    final genres = widget.movie.genres.isNotEmpty
        ? widget.movie.genres
        : [widget.movie.genre];

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
            widget.movie.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Tahun
          Text(
            widget.movie.year,
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
                  border: Border.all(
                    color: AppTheme.primaryGold,
                    width: 1,
                  ),
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
            widget.movie.description,
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
                  onTap: () => widget.appState.toggleWatchlist(widget.movie.id),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1F222B),
                        content: Text(
                          'Memutar ${widget.movie.title}...',
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
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
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_reviews.length, (index) {
              final review = _reviews[index];
              return _buildReviewItem(review, isLast: index == _reviews.length - 1);
            }),
        ],
      ),
    );
  }

  /// Item review individu
  Widget _buildReviewItem(Review review, {bool isLast = false}) {
    // Format tanggal
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final dateStr = '${review.date.day} ${months[review.date.month]} ${review.date.year}';

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
