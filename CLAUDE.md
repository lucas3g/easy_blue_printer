# CLAUDE.md - Easy Blue Printer

## Development Commands

This project uses **FVM** (Flutter Version Management) with Flutter **3.38.9**.

```bash
# Always prefix flutter commands with fvm
fvm flutter pub get                    # Install dependencies
fvm flutter analyze                    # Run static analysis
fvm flutter test                       # Run tests
fvm flutter build apk                  # Build Android
fvm flutter build ios                  # Build iOS

# Example app
cd example && fvm flutter run          # Run example app

# Formatter (page width = 123)
fvm dart format --page-width 123 .
```

## Architecture

### Overview

Flutter plugin for Bluetooth thermal printers. Uses **Clean Architecture / DDD** consistently across Dart, Kotlin (Android), and Swift (iOS) layers.

### Dart Layer (`lib/`)

- **Public API**: `EasyBluePrinter` — singleton accessed via `EasyBluePrinter.instance`
- **Platform Interface**: `EasyBluePrinterPlatform` (abstract) → `MethodChannelEasyBluePrinter` (impl)
- **Method Channel**: `"easy_blue_printer"`
- **Domain**: `domain/entities/` and `domain/enums/` (BluetoothDevice, FS, TA)

### Native Layers (Android & iOS)

Both platforms mirror the same DDD structure:

```
plugin/
├── di/          → AppModule (singleton service locator)
├── data/
│   ├── datasource/   → BluetoothDataSource (raw BT operations)
│   └── repository/   → BluetoothRepositoryImpl
├── domain/
│   ├── repository/   → BluetoothRepository (interface/protocol)
│   ├── usecase/      → One class per operation (GetPairedDevices, ConnectDevice, Print, etc.)
│   └── entities/     → BluetoothDeviceEntity
└── utils/            → Image processing (Android only)
```

- **Android** (`android/src/main/kotlin/com/maktubcompany/easy_blue_printer/`): Kotlin, RFCOMM socket, min SDK 21, compile SDK 31
- **iOS** (`ios/Classes/`): Swift 5.0, CoreBluetooth, min iOS 12.0. Image printing not implemented on iOS.

## Key Conventions

- **FVM**: Always use `fvm flutter` / `fvm dart`, never bare `flutter`/`dart`
- **Formatter page width**: 123 characters (`analysis_options.yaml`)
- **Linting**: `flutter_lints: ^5.0.0`
- **Enum naming**: Short aliases — `FS` (FontSize: normal, medium, large, huge), `TA` (TextAlign: left, center, right)
- **DDD layers**: data → domain → presentation. Use cases are single-responsibility classes.
- **Singleton DI**: `AppModule` object (Kotlin) / class (Swift) — manual service locator, no DI framework
- **Threading**: Native BT operations run on background threads (Android: `Thread.start()`, iOS: async completion blocks)
