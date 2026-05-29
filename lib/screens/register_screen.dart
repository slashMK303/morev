import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/film_logo.dart';
import '../widgets/profile_picker.dart';
import 'movie_list_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../storage/token_storage.dart';
import '../storage/view_storage.dart';
import '../storage/watchlist_storage.dart';
import '../storage/profile_storage.dart';
import '../utils/api_error_handler.dart';
import '../utils/profile_photo_url.dart';

class RegisterScreen extends StatefulWidget {
  final AppState appState;
  const RegisterScreen({super.key, required this.appState});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _motivasiController = TextEditingController();
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();
  String? _profileImagePath;
  XFile? _profileImageFile;
  bool _isLoading = false;
  String? _formServerError;
  final Map<String, String> _fieldServerErrors = {};

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _motivasiController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    setState(() {
      _formServerError = null;
      _fieldServerErrors.clear();
    });

    try {
      final registerResp = await _authService.register(
        payload: {
          'full_name': _namaController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'motivation': _motivasiController.text.trim(),
        },
        profilePhoto: _profileImageFile,
      );

      String? uploadedProfilePath;
      final registerData = registerResp.data;
      if (registerData is Map<String, dynamic>) {
        final responseData = registerData['data'];
        if (responseData is Map<String, dynamic>) {
          final rawPhoto = responseData['profile_photo']?.toString();
          if (rawPhoto != null && rawPhoto.trim().isNotEmpty) {
            uploadedProfilePath = normalizeUploadedProfilePhotoPath(rawPhoto);
          }
        }
      }

      final loginResp = await _authService.login({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final auth = AuthResponse.fromJson(
        Map<String, dynamic>.from(loginResp.data),
      );
      if (auth.accessToken.isNotEmpty) {
        await _tokenStorage.saveToken(auth.accessToken);

        // Simpan profil ke storage lokal untuk auto-login
        await ProfileStorage().saveProfile({
          'full_name': _namaController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'motivation': _motivasiController.text.trim(),
          'profile_photo': uploadedProfilePath,
        });

        // Populate AppState with newly registered user info so UI shows username
        widget.appState.loginOrRegister(
          namaLengkap: _namaController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          kalimatMotivasi: _motivasiController.text.trim(),
          profileImagePath: uploadedProfilePath,
        );
        // Newly registered account likely has empty watchlist; ensure local storage cleared
        try {
          await WatchlistStorage().saveIds(<String>{});
        } catch (_) {}

        try {
          await ViewStorage().saveCount(0);
          widget.appState.setViewCount(0);
          await ProfileStorage().clear();
        } catch (_) {}
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
              Expanded(
                child: Text(
                  'Registrasi berhasil.',
                  style: const TextStyle(
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    } catch (e) {
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
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyApiError(e, fallback: 'Registrasi/login gagal'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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
                const SizedBox(height: 10),
                // Logo dan judul aplikasi
                const FilmLogo(),
                const SizedBox(height: 32),

                // Form Pendaftaran
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
                            'Daftar Akun Baru',
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

                        // Nama Lengkap
                        CustomTextField(
                          label: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap',
                          controller: _namaController,
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('full_name') ||
                                _formServerError != null) {
                              setState(() {
                                _fieldServerErrors.remove('full_name');
                                _formServerError = null;
                              });
                            }
                          },
                          validator: (val) {
                            final serverError = _fieldServerErrors['full_name'];
                            if (serverError != null) {
                              return serverError;
                            }
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama lengkap wajib diisi';
                            }
                            if (val.trim().length < 3) {
                              return 'Nama minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Username
                        CustomTextField(
                          label: 'Username',
                          hintText: 'Pilih username unik',
                          controller: _usernameController,
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('username') ||
                                _formServerError != null) {
                              setState(() {
                                _fieldServerErrors.remove('username');
                                _formServerError = null;
                              });
                            }
                          },
                          validator: (val) {
                            final serverError = _fieldServerErrors['username'];
                            if (serverError != null) {
                              return serverError;
                            }
                            if (val == null || val.trim().isEmpty) {
                              return 'Username wajib diisi';
                            }
                            if (val.trim().contains(' ')) {
                              return 'Username tidak boleh mengandung spasi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email
                        CustomTextField(
                          label: 'Email',
                          hintText: 'email@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
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
                          hintText: 'Buat password yang kuat',
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
                        const SizedBox(height: 20),

                        // Kalimat Motivasi
                        CustomTextField(
                          label: 'Kalimat Motivasi',
                          hintText: 'Tulis kalimat motivasi favoritmu',
                          controller: _motivasiController,
                          maxLines: 2,
                          onChanged: (_) {
                            if (_fieldServerErrors.containsKey('motivation') ||
                                _formServerError != null) {
                              setState(() {
                                _fieldServerErrors.remove('motivation');
                                _formServerError = null;
                              });
                            }
                          },
                          validator: (val) {
                            final serverError =
                                _fieldServerErrors['motivation'];
                            if (serverError != null) {
                              return serverError;
                            }
                            if (val == null || val.trim().isEmpty) {
                              return 'Kalimat motivasi wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Foto Profil
                        ProfilePicker(
                          profileImagePath: _profileImagePath,
                          onImageSelected: (file) {
                            setState(() {
                              _profileImageFile = file;
                              _profileImagePath = file?.path;
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        // Tombol Daftar
                        CustomButton(
                          text: _isLoading ? 'Mendaftar...' : 'Daftar Sekarang',
                          onPressed: _isLoading ? () {} : _register,
                        ),
                        const SizedBox(height: 24),

                        // Tautan ke halaman Login
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
                                      ) => LoginScreen(
                                        appState: widget.appState,
                                      ),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(-1.0, 0.0);
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
                                text: 'Sudah punya akun? ',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Login di sini',
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
                const SizedBox(height: 20),
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
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
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
