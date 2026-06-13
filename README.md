# VivaJauh Mobile
who knows - Technoscape 2026

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
