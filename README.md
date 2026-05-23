# Pembagian Tugas

## Nanang
- [X] Membuat halaman Register
- [X] Membuat halaman Login
- [X] Membuat halaman Dashboard/Home

## Irfan
- [X] Membuat halaman Details
- [X] Membuat halaman Watchlist
- [X] Membuat halaman Profile

## Hydar
- [ ] Membuat halaman Rate History
- [ ] Membuat halaman Watch History

---

# Progress Project

- [X] Register
- [X] Login
- [X] Dashboard/Home
- [X] Details
- [X] Watchlist
- [X] Profile
- [ ] Rate History
- [ ] Watch History

---

## 📂 Struktur Project (Flat & Sangat Sederhana)

Untuk memudahkan pemula dan mempercepat kolaborasi tim, folder diatur tanpa kedalaman yang rumit (*flat structure*):

```
lib/
├── models/      # Tempat format data objek (Contoh: model data film)
├── screens/     # Tempat halaman penuh aplikasi (Login, Register, Dashboard)
├── theme/       # Tempat konfigurasi gaya global (Warna gelap, emas cinema, ukuran font)
├── widgets/     # Tempat komponen visual kustom yang bisa langsung dipasang/dipakai ulang
├── state/       # Manajemen status reaktif sederhana (Profil pengguna & Bookmark/Watchlist)
└── main.dart    # Pintu utama peluncuran aplikasi
```

---

## 🎨 Panduan Visual & Tema (UI/UX Theme)

Tema aplikasi didesain khusus agar terlihat **premium, modern, dan mewah** dengan getaran bioskop (*cinema vibes*):

- **Latar Belakang (Background)**: Abu-abu arang sangat gelap (`#0B0C10`). Hindari warna hitam pekat biasa agar tidak kontras berlebihan.
- **Warna Aksen Utama (Cinema Gold)**: Kuning-Emas menyala (`#FFD700` atau `#EAB308`). Digunakan untuk tombol utama, teks krusial, dan garis penanda aktif.
- **Permukaan Kartu (Slate Card)**: Abu-abu gelap hangat (`#18191E`). Digunakan sebagai background *form* atau card daftar film.
- **Permukaan Kolom Input**: `#1F222B` dengan border tipis `#2C303E`.

Seluruh aturan warna dan gaya teks di atas sudah didaftarkan di dalam [app_theme.dart](file:///c:/marvin/morev/lib/theme/app_theme.dart). Cukup gunakan komponen kustom di bawah ini, maka tampilan otomatis akan konsisten!

---

## 🛠️ Komponen UI Kustom yang Bisa Dipakai Ulang (Reusable Widgets)

Anggota tim **tidak perlu** membuat tombol atau kolom input sendiri. Gunakan saja widget berikut:

### 1. Tombol Utama Premium (`CustomButton`)
Tombol ini sudah dilengkapi efek bayangan emas berpendar (*gold glow shadow*), transisi sentuh responsif (memperkecil skala tombol sedikit saat ditekan), serta ikon opsional.

**Cara Penggunaan:**
```dart
import '../widgets/custom_button.dart';

// 1. Tombol Utama (Warna Emas Solid)
CustomButton(
  text: 'Simpan Review',
  icon: Icons.check_circle_rounded,
  onPressed: () {
    print('Tombol ditekan');
  },
),

// 2. Tombol Sekunder (Garis Tepi / Outlined)
CustomButton(
  text: 'Batal',
  isSecondary: true,
  onPressed: () => Navigator.pop(context),
),
```

### 2. Kolom Input Elegan (`CustomTextField`)
Kolom input dengan gaya modern yang memiliki judul kecil di atasnya, efek garis emas menyala (*glow focus shadow*) ketika diketik, dukungan validasi form bawaan, serta fitur sembunyikan/tampilkan password secara otomatis.

**Cara Penggunaan:**
```dart
import '../widgets/custom_text_field.dart';

CustomTextField(
  label: 'Review Anda',
  hintText: 'Tulis tanggapan Anda mengenai film ini...',
  maxLines: 3, // Fleksibel untuk baris banyak
  prefixIcon: Icons.rate_review_rounded,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Review tidak boleh kosong!';
    }
    return null;
  },
),
```

### 3. Logo Kustom Branding (`FilmLogo`)
Menampilkan kotak kuning-emas melengkung berisi rol film dengan efek pendaran radial mewah di bagian bawahnya, lengkap dengan tulisan **Morev - Movie Review**.

**Cara Penggunaan:**
```dart
import '../widgets/film_logo.dart';

// Di bagian atas halaman login/register
const FilmLogo(),

// Hanya menampilkan ikon tanpa tulisan
const FilmLogo(iconSize: 60, showText: false),
```

### 4. Pemilih Avatar Interaktif (`ProfilePicker`)
Widget berbentuk tombol input unggah yang ketika ditekan akan menampilkan *Bottom Sheet* berisi deretan avatar karakter film yang didesain secara visual eksklusif.

**Cara Penggunaan:**
```dart
import '../widgets/profile_picker.dart';

ProfilePicker(
  selectedAvatarIndex: _mySelectedAvatarIndex,
  onAvatarSelected: (index) {
    setState(() {
      _mySelectedAvatarIndex = index;
    });
  },
),
```

---

## ⚡ Mengakses State Aplikasi (Profil & Watchlist)

Untuk melacak siapa pengguna yang sedang login atau film apa saja yang di-bookmark, kita menggunakan `AppState` reaktif yang terpusat di [app_state.dart](file:///c:/marvin/morev/lib/state/app_state.dart).

**Mendapatkan data user aktif:**
```dart
final user = widget.appState.currentUser;
print(user?.namaLengkap);
print(user?.username);
```

**Mengecek atau mengubah status Watchlist film:**
```dart
// Mengecek apakah film sudah di-bookmark
bool isFav = widget.appState.isWatchlisted(movie.id);

// Menambah/Menghapus dari bookmark
widget.appState.toggleWatchlist(movie.id);
```

---

## 💡 Tips Membuat Halaman Baru dalam 5 Menit!

Jika Anda mendapat tugas membuat halaman baru (misal: **Halaman Tulis Review Baru**):
1. Buat file baru di dalam `screens/`, contoh: `screens/add_review_screen.dart`.
2. Gunakan `Scaffold` biasa dengan `SafeArea`.
3. Buat Form dan susun field Anda menggunakan `CustomTextField`.
4. Tambahkan tombol submit menggunakan `CustomButton`.
5. Hubungkan halaman baru tersebut menggunakan navigasi standard Flutter. 

*Dengan cara ini, halaman baru buatan Anda akan langsung memiliki gaya visual, warna latar, font, dan kolom input yang 100% selaras dengan 3 halaman utama Morev!*
