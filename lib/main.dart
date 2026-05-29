import 'package:flutter/material.dart';
import 'package:morev/screens/login_screen.dart';
import 'package:morev/screens/movie_list_screen.dart';
import 'package:morev/theme/app_theme.dart';
import 'package:morev/state/app_state.dart';
import 'package:morev/storage/token_storage.dart';
import 'package:morev/storage/profile_storage.dart';
import 'package:morev/storage/watchlist_storage.dart';
import 'package:morev/storage/view_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await TokenStorage().getToken();
      if (token != null && token.isNotEmpty) {
        final profileData = await ProfileStorage().loadProfile();
        if (profileData != null) {
          _appState.loginOrRegister(
            namaLengkap: profileData['full_name'] ?? '',
            username: profileData['username'] ?? '',
            email: profileData['email'] ?? '',
            kalimatMotivasi: profileData['motivation'] ?? '',
            profileImagePath: profileData['profile_photo'],
          );

          final watchlistIds = await WatchlistStorage().loadIds();
          _appState.setWatchlistIds(watchlistIds);

          final viewCount = await ViewStorage().loadCount();
          _appState.setViewCount(viewCount);

          _isLoggedIn = true;
        }
      }
    } catch (_) {
      // Jika ada error saat memuat data, anggap belum login
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morev Movie Review',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGold,
                ),
              ),
            )
          : (_isLoggedIn
              ? MovieListScreen(appState: _appState)
              : LoginScreen(appState: _appState)),
    );
  }
}
