import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class WatchHistoryScreen extends StatelessWidget {
  final AppState appState;

  const WatchHistoryScreen({super.key, required this.appState});

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon jam
              const Icon(
                Icons.access_time_rounded,
                size: 80,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 24),
              // Judul kosong
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
              // Subjudul kosong
              const Text(
                'Mulai tonton film favoritmu sekarang',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Tombol jelajah
              SizedBox(
                width: 160,
                child: CustomButton(
                  text: 'Jelajahi Film',
                  onPressed: () {
                    // Pindah ke tab beranda
                    appState.setActiveTab(0);
                    Navigator.pop(context);
                  },
                ),
              ),
              // Jarak kompensasi bawah
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
