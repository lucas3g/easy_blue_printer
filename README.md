# Easy Blue Printer

The **Easy Blue Printer** plugin allows seamless integration of Bluetooth printers in a Flutter app, enabling the scanning, connection, and printing functionality.

## Features
- Scan nearby Bluetooth devices.
- Connect and disconnect from Bluetooth printers.
- Print text data with configurable options such as font size, alignment, and bold text.
- Print empty lines for formatting.

## Installation

1. Add `easy_blue_printer` to your `pubspec.yaml` file:

```yaml
dependencies:
  easy_blue_printer: ^latest_version
```

2. Run `flutter pub get` to install the package.

## Usage

### 1. **Import the Library**

To start using the **Easy Blue Printer** plugin, import the library:

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';
```

### 2. **Scanning Bluetooth Devices**

To scan for nearby Bluetooth devices, use the `scanDevices` method. This will return a list of available devices.

```dart
final _easyBluePrinterPlugin = EasyBluePrinter();
final _devicesStream = StreamController<List<BluetoothDevice>>();

void _scanDevices() async {
  try {
    final List<BluetoothDevice> devices =
        await _easyBluePrinterPlugin.scanDevices();

    _devicesStream.add(devices);
  } catch (e) {
    print(e);
  }
}
```

### 3. **Displaying Devices**

You can display a list of Bluetooth devices with their name, address, and connection status using a `StreamBuilder`:

```dart
StreamBuilder<List<BluetoothDevice>>(
  stream: _devicesStream.stream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasData) {
      final devices = snapshot.data;

      return Column(
        children: devices!.map((device) {
          return ListTile(
            title: Text(device.name),
            subtitle: Text(device.address +
                (device.connected ? ' - Connected' : '')),
            onTap: () async {
              // Connect or Disconnect from the device
            },
          );
        }).toList(),
      );
    }

    return const SizedBox();
  },
)
```

### 4. **Connecting to a Bluetooth Printer**

When a user taps on a device in the list, you can connect or disconnect from the Bluetooth printer using the `connectToDevice` and `disconnectFromDevice` methods:

```dart
final connected = await _easyBluePrinterPlugin.connectToDevice(device);
if (connected) {
  device.setConnected(true);
  setState(() {});
}
```

```dart
final disconnected = await _easyBluePrinterPlugin.disconnectFromDevice();
if (disconnected) {
  device.setConnected(false);
  setState(() {});
}
```

### 5. **Printing Data**

Once connected, you can print text data using the `printData` method:

```dart
await _easyBluePrinterPlugin.printData(
  data: 'Hello World',
  fontSize: FS.normal,
  textAlign: TA.center,
  bold: true,
);
await _easyBluePrinterPlugin.printEmptyLine(callTimes: 5);
```

### 6. **Buttons to Scan and Print**

In the UI, you can use buttons to trigger device scanning and printing functionality:

```dart
ElevatedButton(
  onPressed: _scanDevices,
  child: const Text('Scan Devices'),
)

ElevatedButton(
  onPressed: () async {
    await _easyBluePrinterPlugin.printData(
      data: 'Hello World',
      fontSize: FS.normal,
      textAlign: TA.center,
      bold: true,
    );
    await _easyBluePrinterPlugin.printEmptyLine(callTimes: 5);
  },
  child: const Text('Print Data'),
)
```

## Example UI

Here is a simple UI that integrates scanning, connecting, and printing functionality:

```dart
MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: const Text('Easy Blue Printer Example'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // StreamBuilder to display the list of Bluetooth devices
          StreamBuilder<List<BluetoothDevice>>(
            stream: _devicesStream.stream,
            builder: (context, snapshot) {
              // Handle connection state and display devices
            },
          ),
          ElevatedButton(
            onPressed: _scanDevices,
            child: const Text('Scan Devices'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Trigger the print functionality
            },
            child: const Text('Print Data'),
          ),
        ],
      ),
    ),
  ),
)
```

## License

This project is licensed under the MIT License.

---

With **Easy Blue Printer**, integrating Bluetooth printers into your Flutter app is simple and efficient. Enjoy printing directly from your mobile device with just a few lines of code!