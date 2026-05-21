import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/film_logo.dart';
import 'movie_list_screen.dart';
import 'register_screen.dart';

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

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final input = _userController.text.trim();

      // profil dummy
      if (widget.appState.currentUser == null) {
        widget.appState.loginOrRegister(
          namaLengkap: 'Movie Fanatic',
          username: input.contains('@') ? input.split('@')[0] : input,
          email: input.contains('@') ? input : 'fan@morev.com',
          kalimatMotivasi:
              'Review film adalah seni mengeksplorasi imajinasi tanpa batas!',
          profileImagePath: null,
        );
      }

      // Notifikasi login
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
                  'Selamat Datang Kembali, ${widget.appState.currentUser?.namaLengkap}!',
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

      // Halaman utama
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MovieListScreen(appState: widget.appState),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(
              0.0,
              1.0,
            ); // Transisi geser ke atas
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

                        // Username atau Email
                        CustomTextField(
                          label: 'Username atau Email',
                          hintText: 'Masukkan username atau email',
                          controller: _userController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Username atau Email wajib diisi';
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
                          validator: (val) {
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
                        CustomButton(text: 'Login', onPressed: _login),
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
}
