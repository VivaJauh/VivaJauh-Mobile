# VivaJauh Mobile
who knows - Technoscape 2026

## Architecture

VivaJauh Mobile menggunakan BLoC pattern untuk memisahkan UI, event, state, dan service layer. UI mengirim event ke BLoC, BLoC memproses business flow melalui service/repository, lalu mengembalikan state baru ke widget.

Pola ini dipakai untuk fitur utama seperti autentikasi, sinkronisasi offline, record operasional, dana koperasi, dan pengajuan pinjaman.

## Documentation

- [Project Drive](https://drive.google.com/drive/folders/1Vb6O0SQcC0dWbQb7LDRBHbaWPV7EpNkP?usp=sharing) - aplikasi, ERD, PPT, dan dokumen pendukung.

## Getting Started

1. Install Flutter SDK (>= 3.10.8):

```bash
flutter --version
```

2. Install dependencies:

```bash
flutter pub get
```

3. Create `.env` from the example:

```bash
cp .env.example .env
```

> For local development with the backend API, update `API_BASE_URL` to `http://10.0.2.2:3000/api/v1` (Android emulator) or `http://localhost:3000/api/v1` (iOS simulator).

4. Run the app:

```bash
flutter run
```

## Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
