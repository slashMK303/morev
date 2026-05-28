import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_api.dart';
import '../services/profile_service.dart';
import '../state/app_state.dart';
import '../storage/profile_storage.dart';
import '../storage/token_storage.dart';
import '../storage/view_storage.dart';
import '../storage/watchlist_storage.dart';
import '../utils/api_error_handler.dart';
import '../utils/profile_photo_url.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_picker.dart';
import 'login_screen.dart';
import 'rate_history_screen.dart';
import 'watch_history_screen.dart';

class ProfileTab extends StatefulWidget {
  final AppState appState;

  const ProfileTab({super.key, required this.appState});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ProfileService _profileService = ProfileService();
  final ProfileStorage _profileStorage = ProfileStorage();
  final TokenStorage _tokenStorage = TokenStorage();
  ProfileApi? _profile;
  Map<String, dynamic>? _statistics;
  bool _loading = false;
  String? _error;
  bool _profileLoadedForCurrentVisit = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChange);
    _loadProfile();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (widget.appState.activeTab == 2) {
      if (!_profileLoadedForCurrentVisit) {
        _profileLoadedForCurrentVisit = true;
        _loadProfile();
      }
    } else {
      _profileLoadedForCurrentVisit = false;
    }
  }

  Future<void> _loadProfile() async {
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
      final profileResp = await _profileService.getProfile(token: token);
      final statisticsResp = await _profileService.getStatistics(token: token);
      final localProfile = await _profileStorage.loadProfile();

      if (profileResp.statusCode == 200 && statisticsResp.statusCode == 200) {
        if (mounted) {
          final statisticsData = Map<String, dynamic>.from(
            statisticsResp.data['data'],
          );
          final totalViews = statisticsData['total_views'] is int
              ? statisticsData['total_views']
              : int.tryParse(
                      statisticsData['total_views']?.toString() ?? '0',
                    ) ??
                    0;
          final serverProfile = Map<String, dynamic>.from(
            profileResp.data['data'],
          );
          final mergedProfile = <String, dynamic>{
            ...serverProfile,
            if (localProfile != null) ...localProfile,
          };
          setState(() {
            _profile = ProfileApi.fromJson(mergedProfile);
            _statistics = statisticsData;
          });
          widget.appState.setViewCount(totalViews);
          await ViewStorage().saveCount(totalViews);
        }
      } else if (mounted) {
        setState(() {
          _error = 'Gagal mengambil profil dari server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyApiError(e, fallback: 'Gagal mengambil profil');
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

  Future<void> _showEditProfileDialog() async {
    final currentProfile = _profile;
    if (currentProfile == null) return;

    XFile? selectedProfilePhoto;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProfile() async {
              setDialogState(() => isSaving = true);

              final token = await _tokenStorage.getToken();
              if (token == null) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Token login tidak ditemukan.'),
                    ),
                  );
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                return;
              }

              try {
                String? uploadedProfilePhoto = currentProfile.profilePhoto;
                if (selectedProfilePhoto != null) {
                  try {
                    uploadedProfilePhoto = await _profileService.uploadPhoto(
                      token: token,
                      photo: selectedProfilePhoto!,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            friendlyApiError(
                              e,
                              fallback: 'Gagal mengupload foto profil',
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }

                final updatedProfile = {
                  'id': currentProfile.id,
                  'full_name': currentProfile.fullName,
                  'username': currentProfile.username,
                  'email': currentProfile.email,
                  'motivation': currentProfile.motivation,
                  'profile_photo': uploadedProfilePhoto,
                };

                await _profileStorage.saveProfile(updatedProfile);
                final updated = ProfileApi.fromJson(updatedProfile);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  widget.appState.loginOrRegister(
                    namaLengkap: updated.fullName,
                    username: updated.username,
                    email: updated.email,
                    kalimatMotivasi: updated.motivation,
                    profileImagePath: updated.profilePhoto,
                  );
                  setState(() {
                    _profile = updated;
                  });
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        friendlyApiError(
                          e,
                          fallback: 'Gagal memperbarui profil',
                        ),
                      ),
                    ),
                  );
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.cardGrey,
              title: const Text(
                'Edit Profil',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfilePicker(
                      profileImagePath:
                          selectedProfilePhoto?.path ??
                          currentProfile.profilePhoto,
                      onImageSelected: (file) {
                        setDialogState(() {
                          selectedProfilePhoto = file;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
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
                size: 72,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    final namaLengkap = profile?.fullName ?? 'Pengguna';
    final username = profile?.username ?? 'user';
    final motivasi = profile?.motivation ?? '';
    final initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : '?';
    final totalReviews = _statistics?['total_reviews']?.toString() ?? '0';
    final totalWatchlists = widget.appState.watchlistIds.length.toString();
    final totalViews =
        _statistics?['total_views']?.toString() ??
        widget.appState.viewCount.toString();
    final profilePhotoPath = profile?.profilePhoto;
    final resolvedProfilePhotoUrl = resolveProfilePhotoUrl(profilePhotoPath);
    final isLocalProfilePhoto =
        !kIsWeb &&
        profilePhotoPath != null &&
        profilePhotoPath.trim().isNotEmpty &&
        File(profilePhotoPath).existsSync();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E212E), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGold,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF2C303E),
                        backgroundImage:
                            profilePhotoPath == null ||
                                profilePhotoPath.trim().isEmpty
                            ? null
                            : isLocalProfilePhoto
                            ? FileImage(File(profilePhotoPath))
                            : NetworkImage(resolvedProfilePhotoUrl!),
                        child:
                            (profile?.profilePhoto != null &&
                                profile!.profilePhoto!.isNotEmpty)
                            ? null
                            : Text(
                                initial,
                                style: const TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaLengkap,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email ?? '',
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
                if (motivasi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.inputGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$motivasi"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: _showEditProfileDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGold,
                      side: const BorderSide(color: AppTheme.primaryGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit Profil',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
                  'Statistik',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.movie_filter_rounded,
                        value: totalViews,
                        label: 'Film Ditonton',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.star_border_rounded,
                        value: totalReviews,
                        label: 'Total Review',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.bookmark_border_rounded,
                        value: totalWatchlists,
                        label: 'Watchlist',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E212E), width: 1),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.star_border_rounded,
                  label: 'Riwayat Rating',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RateHistoryScreen(appState: widget.appState),
                      ),
                    );
                  },
                ),
                const Divider(
                  color: Color(0xFF1E212E),
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.access_time_rounded,
                  label: 'Riwayat Nonton',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WatchHistoryScreen(appState: widget.appState),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Clear token and local watchlist storage on logout
                TokenStorage().clearToken();
                try {
                  WatchlistStorage().clear();
                } catch (_) {}
                try {
                  ViewStorage().clear();
                } catch (_) {}
                try {
                  ProfileStorage().clear();
                } catch (_) {}
                widget.appState.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(appState: widget.appState),
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C303E),
            border: Border.all(color: const Color(0xFF3A3E4C), width: 1),
          ),
          child: Icon(icon, color: AppTheme.primaryGold, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
