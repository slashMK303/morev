import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/film_logo.dart';
import '../widgets/profile_picker.dart';
import 'movie_list_screen.dart';
import 'login_screen.dart';

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
  String? _profileImagePath;

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _motivasiController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Simpan data ke state
      widget.appState.loginOrRegister(
        namaLengkap: _namaController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        kalimatMotivasi: _motivasiController.text.trim(),
        profileImagePath: _profileImagePath,
      );

      // Tampilkan notifikasi sukses
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
                  'Registrasi Berhasil! Selamat Datang ${_namaController.text.trim()}',
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

      // ke halaman utama
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

                        // Nama Lengkap
                        CustomTextField(
                          label: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap',
                          controller: _namaController,
                          validator: (val) {
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
                          validator: (val) {
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
                          validator: (val) {
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
                        const SizedBox(height: 20),

                        // Kalimat Motivasi
                        CustomTextField(
                          label: 'Kalimat Motivasi',
                          hintText: 'Tulis kalimat motivasi favoritmu',
                          controller: _motivasiController,
                          maxLines: 2,
                          validator: (val) {
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
                          onImageSelected: (path) {
                            setState(() {
                              _profileImagePath = path;
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        // Tombol Daftar
                        CustomButton(
                          text: 'Daftar Sekarang',
                          onPressed: _register,
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
}
