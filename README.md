# Offline Posts Manager

Flutter lab app for **local post storage** using **SQLite**. Staff can manage posts **without internet**; all data stays on the device.

## Features

- **List** all saved posts (newest first)
- **Open** a post to read full content
- **Create** a new post
- **Edit** an existing post
- **Delete** a post (with confirmation)

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel)
- For Android: Android SDK / emulator or device  
- For iOS: Xcode / simulator (macOS only)  
- On **Windows / Linux / macOS** desktop, SQLite uses `sqflite_common_ffi` (configured in `lib/main.dart`).

## Run the app

```bash
cd offline_posts_manager
flutter pub get
flutter run
```

Pick a device with `flutter devices`. To target Windows desktop:

```bash
flutter run -d windows
```

## Tests

```bash
flutter test
```

## Tech stack

| Piece | Role |
|--------|------|
| [sqflite](https://pub.dev/packages/sqflite) | SQLite on Android / iOS |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | SQLite on desktop for development |
| [path](https://pub.dev/packages/path) | Path to the database file |
| [intl](https://pub.dev/packages/intl) | Date/time formatting |
| [google_fonts](https://pub.dev/packages/google_fonts) | UI typography |

## Project layout

```
lib/
  main.dart                 # App entry, FFI init on desktop
  models/post.dart          # Post model + safe parsing from DB rows
  database/post_database.dart
  screens/                  # List, detail, form
  theme/app_theme.dart
  widgets/app_page_routes.dart
```

## Launcher icon

Icons are generated from `assets/logo.png` via [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons). After changing the image:

```bash
dart run flutter_launcher_icons
```

## License

Private coursework — not for publication to pub.dev (`publish_to: 'none'` in `pubspec.yaml`).
