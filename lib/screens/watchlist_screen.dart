import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/movie_watch_api.dart';
import '../models/watchlist_api.dart';
import '../services/movie_service.dart';
import '../services/watchlist_service.dart';
import '../state/app_state.dart';
import '../storage/token_storage.dart';
import '../utils/api_error_handler.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';

class WatchlistTab extends StatefulWidget {
  final AppState appState;

  const WatchlistTab({super.key, required this.appState});

  @override
  State<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<WatchlistTab> {
  final WatchlistService _watchlistService = WatchlistService();
  final MovieService _movieService = MovieService();
  final TokenStorage _tokenStorage = TokenStorage();
  List<WatchlistApi> _watchlists = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWatchlists();
  }

  Future<void> _loadWatchlists() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Token login tidak ditemukan. Silakan login ulang.';
        });
      }
      return;
    }

    try {
      final resp = await _watchlistService.getWatchlists(token: token);
      if (resp.statusCode == 200) {
        final data = resp.data['data'] as List;
        if (mounted) {
          setState(() {
            _watchlists = data
                .map(
                  (item) =>
                      WatchlistApi.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList();
          });
        }
      } else if (mounted) {
        setState(() {
          _error = 'Gagal mengambil watchlist dari server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyApiError(e, fallback: 'Gagal mengambil watchlist');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeWatchlist(WatchlistApi item) async {
    final token = await _tokenStorage.getToken();
    if (token == null) return;

    try {
      await _watchlistService.removeWatchlist(
        token: token,
        movieId: item.movieId,
      );
      widget.appState.toggleWatchlist(item.movieId.toString());
      if (!mounted) return;
      setState(() {
        _watchlists.removeWhere((element) => element.movieId == item.movieId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(e, fallback: 'Gagal menghapus watchlist'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openMovieUrl(WatchlistApi item) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      final resp = await _movieService.watchMovie(
        token: token,
        movieId: item.movieId,
      );

      if (resp.statusCode == 200) {
        final watchData = MovieWatchApi.fromJson(resp.data);
        final url = Uri.parse(watchData.url);

        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link film: $e')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyApiError(e, fallback: 'Gagal memutar film')),
        ),
      );
    }
  }

  Movie _toMovie(WatchlistApi item) {
    return Movie(
      id: item.movieId.toString(),
      title: item.title,
      description: 'Detail film tersedia dari data watchlist server.',
      genre: '',
      genres: const [],
      year: item.releaseYear,
      rating: 0,
      reviewsCount: 0,
      posterUrl: item.poster,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _loadWatchlists,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_watchlists.isEmpty) {
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
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Tambahkan film dari Beranda!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadWatchlists,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _watchlists.length,
        itemBuilder: (context, index) {
          final item = _watchlists[index];
          final movie = _toMovie(item);
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(
                    movie: movie,
                    appState: widget.appState,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
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
                          'Tahun rilis: ${movie.year}',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _removeWatchlist(item),
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
                            Expanded(
                              child: InkWell(
                                onTap: () => _openMovieUrl(item),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lihat',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black.withValues(
                                            alpha: 0.85,
                                          ),
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
            ),
          );
        },
      ),
    );
  }
}
