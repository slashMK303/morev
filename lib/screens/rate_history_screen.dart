import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RateHistoryScreen extends StatelessWidget {
  final AppState appState;

  const RateHistoryScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // Ambil data ulasan
    final reviews = _getReviews();

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
      body: reviews.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat rating.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final item = reviews[index];
                return _buildRatingCard(item);
              },
            ),
    );
  }

  // Gabungkan ulasan
  List<_RateHistoryItem> _getReviews() {
    // Data default
    return [
      _RateHistoryItem(
        title: 'Inception',
        year: '2010',
        rating: 4,
        comment: 'bagus dan menarik',
        dateStr: '28 April 2026',
        posterUrl:
            'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=200&auto=format&fit=crop',
      ),
      _RateHistoryItem(
        title: 'Forrest Gump',
        year: '1994',
        rating: 4,
        comment: 'bagus',
        dateStr: '28 April 2026',
        posterUrl:
            'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?q=80&w=200&auto=format&fit=crop',
      ),
    ];
  }

  // Desain kartu
  Widget _buildRatingCard(_RateHistoryItem item) {
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
            child: Image.network(
              item.posterUrl,
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
                  item.title,
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
                  item.year,
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
                      item.dateStr,
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

// Model internal ulasan
class _RateHistoryItem {
  final String title;
  final String year;
  final int rating;
  final String comment;
  final String dateStr;
  final String posterUrl;

  _RateHistoryItem({
    required this.title,
    required this.year,
    required this.rating,
    required this.comment,
    required this.dateStr,
    required this.posterUrl,
  });
}
