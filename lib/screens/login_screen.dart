import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/film_logo.dart';
import 'movie_list_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../storage/token_storage.dart';
import '../services/profile_service.dart';
import '../models/profile_api.dart';
import '../services/watchlist_service.dart';
import '../storage/watchlist_storage.dart';
import '../storage/view_storage.dart';
import '../utils/api_error_handler.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;
  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoading = false;
  String? _formServerError;
  final Map<String, String> _fieldServerErrors = {};

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _userController.text.trim();
    final password = _passwordController.text;

    // backend requires email; require user to input email
    if (!input.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1F222B),
          content: Text('Silakan masukkan email untuk login'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    setState(() {
      _formServerError = null;
      _fieldServerErrors.clear();
    });

    try {
      final resp = await _authService.login({
        'email': input,
        'password': password,
      });

      final auth = AuthResponse.fromJson(Map<String, dynamic>.from(resp.data));
      if (auth.accessToken.isNotEmpty) {
        await _tokenStorage.saveToken(auth.accessToken);

        try {
          final profileService = ProfileService();
          final profileResp = await profileService.getProfile(
            token: auth.accessToken,
          );
          if (profileResp.statusCode == 200) {
            final data = Map<String, dynamic>.from(profileResp.data['data']);
            final profile = ProfileApi.fromJson(data);
            widget.appState.loginOrRegister(
              namaLengkap: profile.fullName,
              username: profile.username,
              email: profile.email,
              kalimatMotivasi: profile.motivation,
              profileImagePath: profile.profilePhoto,
            );
          }
        } catch (_) {
          // ignore profile sync errors
        }

        try {
          final watchlistService = WatchlistService();
          final wlResp = await watchlistService.getWatchlists(
            token: auth.accessToken,
          );
          if (wlResp.statusCode == 200) {
            final data = wlResp.data['data'] as List;
            final ids = data
                .map((e) => (e['movie_id']?.toString() ?? ''))
                .where((s) => s.isNotEmpty)
                .toSet();
            widget.appState.setWatchlistIds(ids);
            await WatchlistStorage().saveIds(ids);
          }
        } catch (_) {
          // ignore watchlist sync errors
        }

        try {
          final savedViewCount = await ViewStorage().loadCount();
          widget.appState.setViewCount(savedViewCount);
        } catch (_) {
          // ignore view count load errors
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1F222B),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Login berhasil',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MovieListScreen(appState: widget.appState),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Transisi geser ke atas
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _formServerError = 'Email atau password salah.';
        });
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        if (!mounted) return;
        setState(() {
          _formServerError = 'Email atau password salah.';
          _fieldServerErrors.clear();
        });
        return;
      }

      final fieldErrors = fieldErrorsFromApiError(e);
      if (fieldErrors.isNotEmpty) {
        setState(() {
          _fieldServerErrors
            ..clear()
            ..addAll(fieldErrors);
          _formServerError = fieldErrors.length > 1
              ? 'Periksa kembali input yang ditandai.'
              : null;
        });
        _formKey.currentState?.validate();
      } else if (!mounted) {
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e, fallback: 'Login gagal'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Logo dan judul aplikasi
                const FilmLogo(),
                const SizedBox(height: 36),

                // Area Form Login
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardGrey,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF1E212E),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Selamat Datang Kembali',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (_formServerError != null) ...[
                          _buildServerErrorBanner(_formServerError!),
                          const SizedBox(height: 20),
                        ],

                        // Username atau Email
                        CustomTextField(
                          label: 'Email',
                          hintText: 'Masukkan email terdaftar',
                          controller: _userController,
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('email') ||
                                _formServerError != null) {
                              setState(() {
                                _fieldServerErrors.remove('email');
                                _formServerError = null;
                              });
                            }
                          },
                          validator: (val) {
                            final serverError = _fieldServerErrors['email'];
                            if (serverError != null) {
                              return serverError;
                            }
                            if (val == null || val.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            final emailReg = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailReg.hasMatch(val.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password
                        CustomTextField(
                          label: 'Password',
                          hintText: 'Masukkan password',
                          controller: _passwordController,
                          isPassword: true,
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('password') ||
                                _formServerError != null) {
                              setState(() {
                                _fieldServerErrors.remove('password');
                                _formServerError = null;
                              });
                            }
                          },
                          validator: (val) {
                            final serverError = _fieldServerErrors['password'];
                            if (serverError != null) {
                              return serverError;
                            }
                            if (val == null || val.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (val.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Tombol Login
                        CustomButton(
                          text: _isLoading ? 'Masuk...' : 'Login',
                          onPressed: _isLoading ? () {} : _login,
                        ),
                        const SizedBox(height: 24),

                        // Tautan ke halaman Daftar
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => RegisterScreen(
                                        appState: widget.appState,
                                      ),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;
                                        var tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Daftar di sini',
                                    style: TextStyle(
                                      color: AppTheme.primaryGold,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF301C1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
