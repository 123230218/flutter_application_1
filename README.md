# PC Builder Assistant

Aplikasi mobile untuk memilih, merakit, dan membandingkan komponen PC. Fitur lengkap termasuk build list, rekomendasi AI (Gemini), peta toko komputer, converter, dan mini game quiz.

## Setup

1. Pastikan Flutter SDK dan Android/iOS toolchain sudah terpasang.
2. Jalankan `flutter pub get`.
3. Jalankan aplikasi dengan `flutter run`.

## API Key

Isi API key di file berikut:

- [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart)
	- `YOUR_EXCHANGERATE_API_KEY`
	- `YOUR_GEMINI_API_KEY`

## Struktur Fitur

- Auth lokal dengan SQLite + SHA-256 + salt
- Session 7 hari via `flutter_secure_storage`
- Biometric login (local_auth)
- Parts data dari API dan fallback seed JSON
- Cache parts 1 jam, kurs 6 jam (Hive)
- Peta toko komputer (Overpass + OpenStreetMap)
- AI chat ARIA dan rekomendasi build
- Mini game quiz + leaderboard lokal

## Catatan

- Pastikan permission lokasi, biometrik, kamera, dan internet aktif.
- Data seed komponen berada di [assets/data/parts_seed.json](assets/data/parts_seed.json).
