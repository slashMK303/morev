import 'package:flutter/material.dart';
import '../models/review.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'rate_history_screen.dart';
import 'watch_history_screen.dart';

class ProfileTab extends StatelessWidget {
  final AppState appState;

  const ProfileTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final user = appState.currentUser;
    final namaLengkap = user?.namaLengkap ?? 'Pengguna';
    final username = user?.username ?? 'user';
    final kalimatMotivasi = user?.kalimatMotivasi ?? '';
    final initial = namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : '?';

    // Hitung statistik
    final totalReviews = Review.mockReviews.length;
    final filmDitonton = 0; // Placeholder
    final genreFavorit = '-'; // Placeholder

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // === Card Profil ===
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
                    // Avatar dengan border gold
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
                        child: Text(
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
                    // Nama & username
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (kalimatMotivasi.isNotEmpty) ...[
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
                      '"$kalimatMotivasi"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === Card Statistik ===
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
                        value: '$filmDitonton',
                        label: 'Film Ditonton',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.star_border_rounded,
                        value: '$totalReviews',
                        label: 'Total Review',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.trending_up_rounded,
                        value: genreFavorit,
                        label: 'Genre Favorit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === Menu Riwayat ===
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
                    // Pindah ke riwayat rating
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RateHistoryScreen(appState: appState),
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
                    // Pindah ke riwayat nonton
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WatchHistoryScreen(appState: appState),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === Tombol Logout ===
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                appState.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(appState: appState),
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

  /// Widget item statistik (icon + value + label)
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

  /// Widget item menu (icon + label + chevron)
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
