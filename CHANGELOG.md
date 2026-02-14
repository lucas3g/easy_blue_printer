# Changelog

## [1.3.4] - 2026-02-14
- Updated PIX donation key in README

## [1.3.3] - 2026-02-11
- **FIX** README

## [1.3.2] - 2026-02-11

### Fixed
- **iOS**: Connected peripheral now appears in scan results even if not discovered during scan
- Upgraded Flutter SDK to 3.38.9
- Fixed VS Code launch configuration

## [1.3.1] - 2026-02-10
- **FIX** README

## [1.3.0] - 2026-02-10
### Added
- **iOS**: Image printing support
- **iOS**: `isConnected` use case
- **iOS**: Image processing utilities (scale and bitmap decode)
- **Docs**: Complete bilingual README (English and Portuguese) for pub.dev

### Fixed
- **iOS**: First scan no longer returns empty — waits for CBCentralManager to be ready before scanning
- **iOS**: Scan loading now stays visible until devices are found
- **Android**: Image printing sends data in chunks to avoid buffer overflow
- **Android**: Filter out unnamed devices from scan results

## [1.2.7] - 2025-02-26
### release
- **Added**: Fix erros

## [1.2.6] - 2025-02-26
### release
- **Added**: Fix connect to device

## [1.2.5] - 2025-02-25
### release
- **Added**: Fix get device is connected

## [1.2.4] - 2025-02-24
### release
- **Added**: Fix get device is connected

## [1.2.3] - 2025-02-23
### release
- **Added**: Fix SDK

## [1.2.2] - 2025-02-23
### release
- **Added**: Fix README

## [1.2.1] - 2025-02-23
### release
- **Added**: Request bluetooth permissions in constructor

## [1.2.0] - 2025-02-15
### release
- **Added**: Request bluetooth permissions

## [1.1.4] - 2025-02-15
### release
- **Added**: Fixed Print Image

## [1.1.3] - 2025-02-15
### release
- **Added**: Fixed Print Image

## [1.1.2] - 2025-02-15
### release
- **Added**: Function Print Image

## [1.1.1] - 2025-02-15
### release
- **Added**: Fixed README EN-US

## [1.1.0] - 2025-02-15
### release
- **Added**: Fixed README

## [1.0.9] - 2025-02-15
### release
- **Added**: Fixed ndkVersion android

## [1.0.8] - 2025-02-15
### release
- **Added**: Fixed permissions android

## [1.0.7] - 2025-02-14
### release
- **Added**: Fixed crash

## [1.0.6] - 2025-02-14
### release
- **Added**: Fixed name function => scanDevices to getPairedDevices

## [1.0.5] - 2025-02-14
### release
- **Added**: Fix version kotlin

## [1.0.4] - 2025-02-14
### release
- **Added**: Added THREAD to the functions

## [1.0.3] - 2025-02-14
### release
- **Added**: Get device is connected.

## [1.0.2] - 2025-02-14
### release
- **Added**: Sdk version.

## [1.0.1] - 2025-02-14
### release
- **Added**: Sdk version.

## [1.0.0] - 2025-02-12
### Initial release
- **Added**: Bluetooth device scanning functionality.
- **Added**: Connect and disconnect functionality for Bluetooth printers.
- **Added**: Ability to print text with customizable settings (font size, alignment, bold).
- **Added**: Print empty lines for better formatting.
- **Added**: Example Flutter app for testing and demonstration of the features.