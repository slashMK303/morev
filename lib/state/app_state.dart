import 'package:flutter/material.dart';

class AppUser {
  final String namaLengkap;
  final String username;
  final String email;
  final String kalimatMotivasi;
  final String? profileImagePath;

  AppUser({
    required this.namaLengkap,
    required this.username,
    required this.email,
    required this.kalimatMotivasi,
    this.profileImagePath,
  });
}

class AppState extends ChangeNotifier {
  // Data pengguna saat ini
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Daftar watchlist (disimpan sebagai ID film)
  final Set<String> _watchlistIds = {};
  Set<String> get watchlistIds => _watchlistIds;

  // Tab navigasi bawah yang aktif
  int _activeTab = 0;
  int get activeTab => _activeTab;

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  // Daftar / Masuk pengguna
  void loginOrRegister({
    required String namaLengkap,
    required String username,
    required String email,
    required String kalimatMotivasi,
    String? profileImagePath,
  }) {
    _currentUser = AppUser(
      namaLengkap: namaLengkap,
      username: username,
      email: email,
      kalimatMotivasi: kalimatMotivasi,
      profileImagePath: profileImagePath,
    );
    notifyListeners();
  }

  // Keluar
  void logout() {
    _currentUser = null;
    _watchlistIds.clear();
    _activeTab = 0;
    notifyListeners();
  }

  // Cek apakah film ada di watchlist
  bool isWatchlisted(String id) {
    return _watchlistIds.contains(id);
  }

  // Tambah/hapus dari watchlist
  void toggleWatchlist(String id) {
    if (_watchlistIds.contains(id)) {
      _watchlistIds.remove(id);
    } else {
      _watchlistIds.add(id);
    }
    notifyListeners();
  }
}
