# Easy Blue Printer

## Description
The `easy_blue_printer` is a Flutter package that simplifies connecting to Bluetooth printers for formatted text printing. This example demonstrates how to use the package to list paired Bluetooth devices, connect to a printer, and print text.

---

## Installation
Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  easy_blue_printer: latest_version
```

Replace `latest_version` with the latest version of the package.

---

## Usage

### 1. Setting Up the Bluetooth Controller
Create a `BluetoothController` class to manage Bluetooth connections and printing.

```dart
import 'dart:async';
import 'package:easy_blue_printer/easy_blue_printer.dart';

class BluetoothController {
  final EasyBluePrinter _easyBluePrinterPlugin = EasyBluePrinter.instance;
  final StreamController<List<BluetoothDevice>> _devicesStream =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesStream.stream;

  void startScan() {
    _easyBluePrinterPlugin.getPairedDevices().then((devices) {
      _devicesStream.add(devices);
    });
  }

  void stopScan() {
    _devicesStream.close();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _easyBluePrinterPlugin.connectToDevice(device);
  }

  Future<bool> disconnectFromDevice() async {
    return await _easyBluePrinterPlugin.disconnectFromDevice();
  }

  Future<bool> printData({
    required String data,
    required FS fontSize,
    required TA textAlign,
    required bool bold,
  }) async {
    return await _easyBluePrinterPlugin.printData(
      data: data,
      fontSize: fontSize,
      textAlign: textAlign,
      bold: bold,
    );
  }

  Future<void> printEmptyLine({required int callTimes}) async {
    await _easyBluePrinterPlugin.printEmptyLine(callTimes: callTimes);
  }

  Future<bool> isConnected() async {
    return await _easyBluePrinterPlugin.isConnected();
  }

  Future<bool> printImage({required String path, required TA textAlign}) async {
    final bytes =
        await rootBundle.load(path).then((value) => value.buffer.asUint8List()); //GET IMAGE FROM ASSETS

    return await _easyBluePrinterPlugin.printImage(
        bytes: bytes, textAlign: textAlign);
  }
}
```

---

### 2. Creating the User Interface
Now, create a Flutter application that allows listing Bluetooth devices, connecting to a printer, and sending text for printing.

```dart
import 'package:flutter/material.dart';
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'bluetooth_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BluetoothController bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    bluetoothController.startScan();
  }

  @override
  void dispose() {
    bluetoothController.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Easy Blue Printer Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothController.devicesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No devices found');
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final device = snapshot.data![index];

                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text('${device.address} - ${device.connected}'),
                          onTap: () async {
                            final connected = await bluetoothController.connectToDevice(device);
                            device.setConnected(connected);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await bluetoothController.printData(
                    data: 'Hello, World!',
                    fontSize: FS.normal,
                    textAlign: TA.center,
                    bold: false,
                  );
                  await bluetoothController.printEmptyLine(callTimes: 5);
                },
                child: const Text('Print'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await bluetoothController.disconnectFromDevice();
                },
                child: const Text('Disconnect'),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Features
- List paired Bluetooth devices.
- Connect to a Bluetooth printer.
- Send formatted text for printing.
- Print blank lines.
- Disconnect from the printer.

---

## Contribution
If you want to contribute to improving `easy_blue_printer`, feel free to open a PR or report issues on the repository.

---

## License
This project is distributed under the MIT license. For more details, see the `LICENSE` file.

---