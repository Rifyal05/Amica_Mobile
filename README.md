# Arsitektur Frontend Flutter (Amica Mobile)

Dokumen ini memaparkan arsitektur, pola desain, sistem antarmuka, dan mekanisme operasional dari sisi klien aplikasi seluler Amica yang dikembangkan menggunakan kerangka kerja Flutter.
## 0. UI GALERI
- Lihat UI Galeri : [UI GALERI](UI_GALERY.md)
## 1. Ekosistem Proyek

Aplikasi Flutter ini bertindak sebagai klien (Front-End) yang berkomunikasi secara langsung dengan layanan-layanan berikut:
*   Backend & API: [Amica Webservice](https://github.com/Rifyal05/amica_webservice)
*   AI Engine: [Amica AI Engine](https://github.com/fajar123j/amica_ai_engine)
*   *Catatan: Sistem AI Inferensi ONNX dan RAG LLM berjalan di dalam ekosistem Backend, sehingga klien Flutter hanya menerima hasil analisis bersih via HTTP/WebSocket.*

## 2. Struktur Direktori Utama (`lib/`)

Proyek disusun menggunakan pemisahan *layer* yang sangat ketat untuk memastikan skalabilitas kode:
*   `/models`: Kelas data murni (Data Transfer Objects) dengan metode serialisasi JSON.
*   `/provider`: Lapis *State Management* (ViewModel) yang mengatur logika bisnis dan state reaktif UI.
*   `/services`: Lapis abstraksi infrastruktur untuk API HTTP, WebSocket, dan autentikasi.
*   `/theme`: Konfigurasi warna.
*   `/mainpage`: Kumpulan *screens* (View) utama aplikasi (Home, Chat, Profile, Discover).
*   `/login`: Alur layar autentikasi, registrasi, lupa sandi, dan pembuatan PIN.
*   `/navigation`: Manajemen rute bawah (Bottom Navigation Bar) dan tumpukan halaman.

## 3. Pola Desain dan Manajemen Status (State Management)

Aplikasi ini menganut pola arsitektur **MVVM-Service (Model - View - ViewModel / Provider - Service)** terpusat.
Manajemen *state* global dideklarasikan di level tertinggi (`main.dart`) menggunakan `MultiProvider`, yang meliputi:
*   `AuthProvider`: Mengelola sesi JWT, profil pengguna aktif, Google OAuth, dan status PIN.
*   `ChatProvider`: Mengelola daftar *inbox*, tembolok (*cache*) pesan per ruangan, dan siklus hidup Socket.IO.
*   `PostProvider` & `ProfileProvider`: Mengontrol data linimasa (feed), interaksi (Like/Save/Follow) dengan prinsip *Optimistic UI Update* (UI berubah instan tanpa menunggu respons server).
*   `ModerationProvider`: Menangani alur banding (appeal) konten yang diblokir oleh AI Backend.

## 4. Desain Antarmuka (UI/UX) dan Theming

Aplikasi dibangun menggunakan pedoman **Material Design 3** dengan dukungan adaptivitas tinggi:
*   Dynamic Theming (`theme_provider.dart`): Mengizinkan transisi mode Terang/Gelap (Light/Dark Mode) secara *real-time* yang diikat ke `SharedPreferences` agar preferensi pengguna persisten.
*   Dynamic Font Scaling (`font_provider.dart`): Mendukung aksesibilitas bagi pengguna dengan kendala penglihatan melalui *slider* ukuran teks di menu pengaturan yang menerapkan `TextScaler.linear`.
*   Adaptive Widgets: Penggunaan `AdaptiveImageCard` untuk merender gambar dengan proporsi aspek dinamis, serta `ExpandableCaption` untuk memotong takarir teks panjang (Read More/Show Less) demi kenyamanan pembacaan *feed*.

## 5. Manajemen Jaringan dan Keamanan (Networking)

### 5.1. Interseptor Autentikasi (AuthenticatedClient)
Seluruh komunikasi HTTP REST tidak menggunakan pemanggilan `http` standar secara langsung, melainkan dibungkus oleh `AuthenticatedClient`.
*   Auto-Refresh Token: Jika API mengembalikan status `401 Unauthorized`, interseptor akan secara otomatis menunda (pause) permintaan, memanggil `AuthService.refreshToken()` untuk mendapatkan JWT akses baru, dan mengulang permintaan asli tanpa disadari oleh pengguna.

### 5.2. Penyimpanan Kredensial Aman
Token JWT dan data identitas disimpan di `shared_preferences`. Data ini diperiksa pada fase *booting* awal `MyApp` untuk mengarahkan pengguna ke layar Login, Pembuatan Sandi, verifikasi PIN, atau langsung menuju Beranda.

## 6. Komunikasi Real-time (WebSockets)

Fitur pesan instan dibangun menggunakan `socket_io_client` di dalam `ChatProvider`.
*   Koneksi Efisien: Soket hanya melakukan terminasi awal (`connect`) ketika otentikasi berhasil. Soket segera diputus (`disconnect` & `dispose`) saat *logout*.
*   Pendengar Event Moderasi: Aplikasi bereaksi langsung terhadap pancaran `moderation_blocked` atau `moderation_warning`. Saat pelanggaran terdeteksi, UI memunculkan *Dialog* interupsi seketika untuk memberi tahu pengguna mengenai status sanksi AI mereka.

## 7. Push Notifications dan Deep Linking

### 7.1. OneSignal Integration
Distribusi notifikasi latar belakang dikelola via `OneSignal_flutter`. Pada berkas `main.dart`, metode `addClickListener` diinisialisasi untuk menangkap muatan data (payload) dari notifikasi yang diklik. Jika notifikasi memuat rujukan obrolan atau postingan, aplikasi akan memanggil *Navigator* untuk langsung meloncat ke `ChatPage` atau `PostDetailPage`.

### 7.2. Tautan Mendalam (App Links)
Mendukung URI kustom `amica://` untuk memfasilitasi peralihan instan dari luar aplikasi.
*   Tautan Undangan: `amica://join/<chat_id>` akan merender halaman partisipasi grup secara langsung.
*   Bagikan Postingan: `amica://post/<post_id>` secara otomatis menembakkan *overlay loading*, menarik rincian postingan, lalu memunculkan `PostDetailPage`.

## 8. Mekanisme Cache dan Performa

Untuk menjaga batas memori (RAM) klien dan mengurangi beban jaringan:
*   Custom Cache Managers: Diatur oleh kelas `PostCacheManager` (kedaluwarsa 3 hari, batas 30 objek) dan `ProfileCacheManager` (kedaluwarsa 7 hari, batas 30 objek).
*   Manajemen Cache Global: Tersedia fitur pembersihan memori total (*Clear System Cache*) di layar Pengaturan untuk mereset seluruh *Local App Directory*.

## 9. Uji Mutu Kode (Quality Assurance)

Kestabilan klien dijamin dengan pengujian otomatis di direktori `/test/` dan `/integration_test/`:
*   Unit Testing: Menguji serialisasi Model (SDQ, Post, User, Chat) dan logika fungsi murni.
*   Provider/ViewModel Testing: Menggunakan pustaka tiruan `mockito` untuk memverifikasi pengelolaan status (contoh: memvalidasi bahwa `attemptLogin` akan mengganti parameter `isLoggedIn` menjadi `true`).
*   Widget Testing: Menguji gestur UI dengan memalsukan jalur *routing* (`MockNavigatorObserver`) untuk menjamin transisi tombol aman.
*   E2E Integration Testing: Menjalankan mesin uji menyeluruh di perangkat nyata/emulator (contoh skenario `sdq_flow_test.dart` mengautomasi proses login, menjawab 25 soal, dan memvalidasi skor hasil akhir).

## 10. Panduan Kompilasi dan Pengembangan (Build & Run)

### 10.1. Inisialisasi Environment
Buat berkas `.env` di direktori utama `amica/` sebelum melakukan *build*.
```
SERVER_CLIENT_ID=<google-oauth-client-id>
BASE_URL=https://withamica.my.id
ONESIGNAL_APP_ID=<onesignal-app-id>
```
10.2. Instalasi Ketergantungan dan Generator Kode

Jalankan instruksi berikut untuk mengambil paket Dart dan meregenerasi kelas
tiruan (mocks) untuk testing:
```
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```
10.3. Kompilasi (Run/Build)

Menjalankan mode pengawakutuan (Debug):
```
flutter run
```
Kompilasi produksi (Release) untuk perangkat Android (App Bundle):
```
flutter build appbundle --release
```
























