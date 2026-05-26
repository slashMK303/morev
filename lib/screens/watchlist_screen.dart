import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';

class WatchlistTab extends StatelessWidget {
  final AppState appState;

  const WatchlistTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final watchlistIds = appState.watchlistIds;
    final watchlistMovies = Movie.mockMovies
        .where((m) => watchlistIds.contains(m.id))
        .toList();

    if (watchlistMovies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'Watchlist kamu masih kosong.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tambahkan film dari Beranda!',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: watchlistMovies.length,
      itemBuilder: (context, index) {
        final movie = watchlistMovies[index];
        return _buildWatchlistCard(context, movie);
      },
    );
  }

  /// Card film di watchlist
  Widget _buildWatchlistCard(BuildContext context, Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E212E), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              movie.posterUrl,
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
          // Info dan aksi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  movie.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  movie.year,
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.primaryGold,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      movie.rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.people_rounded,
                      color: AppTheme.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.reviewsCount.toString(),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Hapus dari watchlist
                    Expanded(
                      child: InkWell(
                        onTap: () => appState.toggleWatchlist(movie.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C303E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_remove_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lihat detail
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(
                                movie: movie,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: Colors.black.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Lihat',
                                style: TextStyle(
                                  fontSize: 11.5,
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
          ),
        ],
      ),
    );
  }
}
