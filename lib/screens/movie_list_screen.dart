import 'package:flutter/material.dart';
import 'package:morev/services/api_client.dart';
import '../models/movie.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'movie_detail_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
import '../services/movie_service.dart';
import '../services/watchlist_service.dart';
import '../storage/token_storage.dart';
import '../storage/watchlist_storage.dart';
import '../utils/api_error_handler.dart';
import '../models/movie_api.dart';
import '../models/movie_watch_api.dart';
import '../models/genre_api.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieListScreen extends StatefulWidget {
  final AppState appState;
  const MovieListScreen({super.key, required this.appState});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PageController _pageController;
  String _searchQuery = '';
  String _selectedGenre = 'Semua';
  final MovieService _movieService = MovieService();
  final WatchlistService _watchlistService = WatchlistService();
  final TokenStorage _tokenStorage = TokenStorage();
  final List<String> _genres = ['Semua'];
  List<Movie> _movies = [];
  bool _loadingMovies = false;
  String? _movieError;
  bool _moviesLoadedForCurrentVisit = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.appState.activeTab);
    widget.appState.addListener(_onStateChange);
    // Load persisted watchlist IDs so UI reflects saved state immediately
    () async {
      try {
        final ids = await WatchlistStorage().loadIds();
        if (ids.isNotEmpty) widget.appState.setWatchlistIds(ids);
      } catch (_) {}
    }();
    _loadGenres();
    _loadMovies();
  }

  Future<void> _loadGenres() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return;

    try {
      final resp = await _movieService.getGenres(token: token);
      if (resp.statusCode == 200) {
        final data = resp.data['data'] as List;
        final apiGenres = data
            .map((e) => GenreApi.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        if (mounted) {
          setState(() {
            _genres.clear();
            _genres.add('Semua');
            _genres.addAll(apiGenres.map((g) => g.name));
            // Sort, keeping 'Semua' at the beginning
            final names = _genres.sublist(1);
            names.sort();
            _genres.clear();
            _genres.add('Semua');
            _genres.addAll(names);
          });
        }
      }
    } catch (_) {
      // Fail silently for genres, fallback to ['Semua']
    }
  }

  Future<void> _loadMovies() async {
    setState(() {
      _loadingMovies = true;
      _movieError = null;
    });
    final token = await _tokenStorage.getToken();
    if (token == null) {
      setState(() {
        _loadingMovies = false;
        _movieError = 'Token login tidak ditemukan. Silakan login ulang.';
      });
      return;
    }

    try {
      final resp = await _movieService.getMovies(token: token);
      if (resp.statusCode == 200) {
        final data = resp.data['data'] as List;
        final apiMovies = data
            .map((e) => MovieApi.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _movies = apiMovies.map((m) => m.toMovie()).toList();
          _movieError = null;
        });
      } else {
        setState(() {
          _movieError = 'Gagal mengambil movie dari server.';
        });
      }
    } catch (e) {
      setState(() {
        _movieError = friendlyApiError(
          e,
          fallback: 'Gagal mengambil movie',
        );
      });
    } finally {
      if (mounted) setState(() => _loadingMovies = false);
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChange);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (widget.appState.activeTab == 0) {
      if (!_moviesLoadedForCurrentVisit) {
        _moviesLoadedForCurrentVisit = true;
        _loadMovies();
      }
    } else {
      _moviesLoadedForCurrentVisit = false;
    }
    setState(() {});
  }

  Future<void> _toggleWatchlist(Movie movie) async {
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

    final movieId = int.tryParse(movie.id);
    if (movieId == null) return;

    final isAdded = widget.appState.isWatchlisted(movie.id);

    try {
      if (isAdded) {
        await _watchlistService.removeWatchlist(token: token, movieId: movieId);
      } else {
        await _watchlistService.addWatchlist(token: token, movieId: movieId);
      }
      widget.appState.toggleWatchlist(movie.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(
              e,
              fallback: 'Gagal memperbarui watchlist',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void showMovieDetail(Movie movie) {
    showDialog(
      context: context,
      builder: (context) {
        final isAdded = widget.appState.isWatchlisted(movie.id);

        return Dialog(
          backgroundColor: AppTheme.cardGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gambar header
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        movie.posterUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220,
                            color: const Color(0xFF1E212E),
                            child: const Icon(
                              Icons.movie_rounded,
                              size: 64,
                              color: AppTheme.primaryGold,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              movie.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            movie.year,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.primaryGold,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.people_alt_rounded,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${movie.reviewsCount} Reviews',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sinopsis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.description,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: isAdded ? 'Tersimpan' : 'Watchlist',
                              isSecondary: true,
                              icon: isAdded
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await _toggleWatchlist(movie);
                                if (mounted) {
                                  navigator.pop();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Tonton Trailer',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF1F222B),
                                    content: Text(
                                      'Memutar Trailer ${movie.title}...',
                                      style: const TextStyle(
                                        color: AppTheme.primaryGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
    );
  }

  Future<void> _openMovieUrl(Movie movie) async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      final movieId = int.tryParse(movie.id);
      if (movieId == null) return;

      final resp = await _movieService.watchMovie(
        token: token,
        movieId: movieId,
      );

      if (resp.statusCode == 200) {
        final watchData = MovieWatchApi.fromJson(resp.data);
        final url = Uri.parse(watchData.url);
        
        try {
          // Attempt to launch directly as canLaunchUrl can be unreliable
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

  Widget _buildMovieCard(Movie movie) {
    print("URL Poster: ${movie.posterUrl}"); // Debug URL poster
    final isAdded = widget.appState.isWatchlisted(movie.id);

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
        margin: const EdgeInsets.only(bottom: 18),
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
                '${ApiClient.baseUrl}/uploads/${movie.posterUrl}',
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
                      // Watchlist / Tersimpan
                      Expanded(
                        child: InkWell(
                          onTap: () => _toggleWatchlist(movie),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? const Color(0xFF2C303E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAdded
                                    ? Colors.transparent
                                    : const Color(0xFF2C303E),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isAdded
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  size: 14,
                                  color: isAdded
                                      ? AppTheme.primaryGold
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAdded ? 'Tersimpan' : 'Watchlist',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isAdded
                                        ? AppTheme.primaryGold
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Lihat (Open Browser)
                      Expanded(
                        child: InkWell(
                          onTap: () => _openMovieUrl(movie),
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
                                  color: Colors.black.withOpacity(0.85),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Lihat',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black.withOpacity(0.85),
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
  }

  Widget _buildHomeTab() {
    final filteredMovies = _movies.where((movie) {
      final matchesSearch =
          movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          movie.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre =
          _selectedGenre == 'Semua' || movie.genres.contains(_selectedGenre);
      return matchesSearch && matchesGenre;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header pencarian & filter
          Row(
            children: [
              // pencarian
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF1E212E),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari film...',
                            hintStyle: TextStyle(
                              color: Color(0xFF5E6577),
                              fontSize: 14,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Tombol filter
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E212E),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _showFilterBottomSheet();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loadingMovies
                ? const Center(child: CircularProgressIndicator())
                : (_movieError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _movieError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : (filteredMovies.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.movie_filter_rounded,
                                    size: 64,
                                    color: AppTheme.textMuted,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada film yang cocok.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredMovies.length,
                                itemBuilder: (context, index) {
                                  return _buildMovieCard(filteredMovies[index]);
                                },
                              ))),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final genres = _genres;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.cardGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: genres.map((genre) {
                  final isSelected = _selectedGenre == genre;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGenre = genre;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGold
                              : AppTheme.textMuted,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppTheme.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.appState.activeTab;
    final watchlistCount = widget.appState.watchlistIds.length;

    // Judul AppBar dinamis sesuai tab
    final appBarTitles = ['Morev', 'Watchlist', 'Profil'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appBarTitles[activeTab],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppTheme.primaryGold,
                letterSpacing: 0.5,
              ),
            ),
            // Subtitle untuk tab Watchlist
            if (activeTab == 1)
              Text(
                '$watchlistCount film tersimpan',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (widget.appState.activeTab != index) {
            widget.appState.setActiveTab(index);
          }
        },
        children: [
          _buildHomeTab(),
          WatchlistTab(appState: widget.appState),
          ProfileTab(appState: widget.appState),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeTab,
        onTap: (index) {
          widget.appState.setActiveTab(index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_outlined),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
