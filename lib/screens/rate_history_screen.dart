import 'package:flutter/material.dart';
import '../models/review.dart';
import '../storage/review_storage.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RateHistoryScreen extends StatefulWidget {
  final AppState appState;

  const RateHistoryScreen({super.key, required this.appState});

  @override
  State<RateHistoryScreen> createState() => _RateHistoryScreenState();
}

class _RateHistoryScreenState extends State<RateHistoryScreen> {
  final ReviewStorage _reviewStorage = ReviewStorage();
  List<Review> _reviews = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
    });

    final reviews = await _reviewStorage.loadReviews();
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loading = false;
    });
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
          'Riwayat Rating',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : _reviews.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat rating.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final item = _reviews[index];
                return _buildRatingCard(item);
              },
            ),
    );
  }

  // Desain kartu
  Widget _buildRatingCard(Review item) {
    final posterUrl = '';
    final movieTitle = 'Movie #${item.movieId}';
    final movieYear = '-';
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
        '${item.date.day} ${months[item.date.month]} ${item.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E212E), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster film
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: posterUrl.isEmpty
                ? Container(
                    width: 90,
                    height: 125,
                    color: const Color(0xFF1E212E),
                    child: const Icon(
                      Icons.movie_rounded,
                      color: AppTheme.primaryGold,
                      size: 28,
                    ),
                  )
                : Image.network(
                    posterUrl,
                    width: 90,
                    height: 125,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 90,
                        height: 125,
                        color: const Color(0xFF1E212E),
                        child: const Icon(
                          Icons.movie_rounded,
                          color: AppTheme.primaryGold,
                          size: 28,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 16),
          // Detail riwayat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  movieTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Tahun
                Text(
                  movieYear,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 6),
                // Bintang rating
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < item.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: i < item.rating
                          ? AppTheme.primaryGold
                          : AppTheme.textMuted,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                // Teks ulasan
                Text(
                  item.comment,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Tanggal
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
