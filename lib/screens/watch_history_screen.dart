import 'package:flutter/material.dart';
import 'package:morev/services/api_client.dart';
import '../models/history_api.dart';
import '../services/history_service.dart';
import '../state/app_state.dart';
import '../storage/token_storage.dart';
import '../utils/api_error_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class WatchHistoryScreen extends StatefulWidget {
  final AppState appState;

  const WatchHistoryScreen({super.key, required this.appState});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final TokenStorage _tokenStorage = TokenStorage();
  List<HistoryApi> _histories = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
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
      final resp = await _historyService.getHistories(token: token);
      if (resp.statusCode == 200) {
        final data = resp.data['data'] as List;
        if (mounted) {
          setState(() {
            _histories = data
                .map(
                  (item) =>
                      HistoryApi.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList();
          });
        }
      } else if (mounted) {
        setState(() {
          _error = 'Gagal mengambil riwayat nonton.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyApiError(
            e,
            fallback: 'Gagal mengambil riwayat nonton',
          );
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
          'Riwayat Nonton',
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
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      child: CustomButton(
                        text: 'Coba Lagi',
                        onPressed: _loadHistories,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _histories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 80,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Belum ada riwayat nonton',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mulai tonton film favoritmu sekarang',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 160,
                      child: CustomButton(
                        text: 'Jelajahi Film',
                        onPressed: () {
                          widget.appState.setActiveTab(0);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryGold,
              onRefresh: _loadHistories,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: _histories.length,
                itemBuilder: (context, index) {
                  final item = _histories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1E212E),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '${ApiClient.baseUrl}/uploads/${item.poster}',
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
                              Text(
                                'Movie ID: ${item.movieId}',
                                style: const TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.watchedAt,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
