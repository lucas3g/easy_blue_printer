# Changelog

## [1.4.2] - 2026-04-07

### Fixed
- **`printEmptyLine` freeze**: flushing all accumulated text inside `printEmptyLine` caused a large burst that triggered RFCOMM flow control, hanging the printer. `printEmptyLine` now only appends newlines to the buffer — the buffer is sent as one stream by `commitPrint()` when the queue empties (or by `printImage()` before image data).

## [1.4.1] - 2026-04-07

### Fixed
- **Android**: Image printing regression introduced in 1.4.0 — alignment bytes were being flushed as a separate Bluetooth packet before the image data, which some printer firmware could not handle. They are now sent together with the first image chunk, restoring the original behavior.

## [1.4.0] - 2026-04-07

### Changed (breaking improvement)
- **Print buffering**: `printData` and `printEmptyLine` no longer send data immediately. Instead, bytes are accumulated in an in-memory buffer and transmitted as a single continuous stream when:
  - `printEmptyLine` is called (natural flush point at end of receipt)
  - `printImage` is called (text is flushed first, then image is sent)
  - The print queue empties (automatic flush for text-only receipts)
- This eliminates the root cause of corrupted output: the printer now receives one uninterrupted byte stream instead of many small bursts with gaps between them
- Removed `commandDelay` (no longer needed)
- Added internal `commitPrint` mechanism (called automatically — no API change required)

### Fixed
- Corrupted characters when printing PDFs with multiple text items and/or images

## [1.3.9] - 2026-04-07

### Added
- `EasyBluePrinter.instance.commandDelay` — configurable delay between consecutive print commands (default: 100ms). Increase if your printer still shows corrupted output (e.g. `commandDelay = Duration(milliseconds: 150)`). Set to `Duration.zero` to disable.

### Fixed
- The inter-command delay is only applied when there are more jobs in the queue, so the last command does not add unnecessary latency

## [1.3.8] - 2026-04-07

### Fixed
- **Android**: `printData` now consolidates all ESC/POS bytes into a single buffer and sends in 128-byte chunks with 10ms delays between chunks, preventing printer buffer overflow on receipts with many items
- **iOS**: `writeData` now always applies 10ms delay after each BLE chunk regardless of write type (`withResponse` or `withoutResponse`), ensuring consistent flow control across all printer models

## [1.3.7] - 2026-04-07

### Fixed
- **Print queue**: Multiple sequential print calls (`printData`, `printImage`, `printEmptyLine`) are now processed one at a time through an internal queue, eliminating corrupted characters caused by buffer overflow on the printer
- **Android**: Replaced independent threads with a `SingleThreadExecutor` for all print operations, ensuring native-level serialization
- **iOS**: Replaced `DispatchQueue.global()` with a dedicated serial queue for print operations, ensuring native-level serialization
- No more need for manual delays (`Future.delayed`) between print calls in the consuming app

## [1.3.6] - 2026-03-31

### Changed
- Updated README with `PaperConfig` documentation (API reference, quick start, enums table) in English and Portuguese

## [1.3.5] - 2026-03-30

### Added
- **`PaperConfig`** entity to configure paper roll size dynamically (`roll58mm` = 384px, `roll80mm` = 576px, or custom `widthPixels`)
- **`EasyBluePrinter.configurePrinter(PaperConfig)`** method — call once after connecting to set the roll width used for image printing on both Android and iOS

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