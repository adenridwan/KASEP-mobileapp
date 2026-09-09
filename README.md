# KASEP - Kas Sehat Personal

**Atur Arus, Sehatkan Kas.**

Aplikasi pencatatan keuangan pribadi berbasis Flutter untuk Android.

## Fitur Utama

### Autentikasi & Keamanan
- Login dengan **PIN 6 digit**
- Dukungan **biometrik** (sidik jari/wajah)
- Data tersimpan **terenkripsi** di perangkat

### Pencatatan Transaksi
- Catat **kas masuk** dan **kas keluar**
- Kategorisasi transaksi
- Keyboard numerik custom untuk input nominal
- Catatan/deskripsi untuk setiap transaksi

### Laporan & Analisis
- **Saldo berjalan** harian dalam bentuk grafik
- **Ringkasan kategori** pengeluaran
- **Laporan bulanan** dengan perbandingan
- **Analisis** pola pengeluaran per hari

### Ekspor & Bagikan
- Export laporan ke **PDF**
- Export data ke **CSV**
- Bagikan langsung via WhatsApp, Email, dll

### Pengaturan
- Foto profil
- Toggle biometrik
- Manajemen kategori
- Shortcut logout

## Tech Stack

- **Framework:** Flutter 3.x
- **Database:** SQLite (sqflite)
- **Auth:** local_auth + flutter_secure_storage
- **PDF:** pdf package
- **Share:** share_plus

## Cara Build APK

```bash
# Clone repository
git clone https://github.com/adenridwan/KASEP-mobileapp.git
cd KASEP-mobileapp

# Install dependencies
flutter pub get

# Build release APK
flutter build apk --release

# APK akan ada di:
# build/app/outputs/flutter-apk/app-release.apk
```

Atau gunakan script `build_apk.bat` (Windows):
```bash
build_apk.bat
```

## Struktur Folder

```
lib/
├── core/
│   ├── constants/     # Kategori, konstanta
│   ├── services/      # AuthService
│   ├── storage/       # Database, Repository
│   ├── theme/         # Warna, styling
│   ├── utils/         # Formatter
│   └── widgets/       # Widget reusable
├── features/
│   ├── auth/          # Login, PIN setup
│   ├── home/          # Dashboard utama
│   ├── transactions/  # CRUD transaksi
│   ├── categories/    # Kategori pengeluaran
│   ├── reports/       # Laporan mingguan
│   ├── analysis/      # Analisis bulanan
│   ├── settings/      # Pengaturan
│   └── export/        # Export PDF/CSV
├── models/            # Model data
└── navigation/        # Navigasi utama
```

## Screenshots

*Coming soon*

## License

MIT License

---


