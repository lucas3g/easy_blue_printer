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

## Permissions

### For Android
To enable Bluetooth functionality on Android, you need to add the following permissions in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

### For iOS
For iOS, you need to add the following entries to your `Info.plist` file:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>O aplicativo precisa de acesso ao Bluetooth para conectar-se a dispositivos próximos.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>O aplicativo precisa acessar o Bluetooth para comunicação com dispositivos externos.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>O aplicativo usa Bluetooth para se conectar a dispositivos compatíveis.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>O aplicativo precisa acessar a rede local para comunicação com dispositivos Bluetooth.</string>
```

## Usage

### 1. **Import the Library**

To start using the **Easy Blue Printer** plugin, import the library:

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';
```

### 2. **BluetoothController Implementation**

You can create a controller class (`BluetoothController`) to manage the scanning, connecting, and printing functionality:

```dart
class BluetoothController {
  final EasyBluePrinter _easyBluePrinterPlugin = EasyBluePrinter();
  final StreamController<List<BluetoothDevice>> _devicesStream =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesStream.stream;

  void startScan() {
    _easyBluePrinterPlugin.scanDevices().then((devices) {
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
}
```

### 3. **Main Application**

The main application can use the `BluetoothController` to manage Bluetooth devices, scan for them, and send print commands. Here's an example of the main app structure:

```dart
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
    bluetoothController.startScan(); // Start scanning when the screen is loaded
  }

  @override
  void dispose() {
    bluetoothController.stopScan(); // Stop scanning when the screen is discarded
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
                    return Text('Nenhum dispositivo encontrado');
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final device = snapshot.data![index];

                        return ListTile(
                          title: Text(device.name),
                          subtitle:
                              Text('${device.address} - ${device.connected}'),
                          onTap: () async {
                            final connected = await bluetoothController
                                .connectToDevice(device);

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
                child: const Text('Imprimir'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await bluetoothController.disconnectFromDevice();
                },
                child: const Text('Desconectar'),
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

## License

This project is licensed under the MIT License.

---

With **Easy Blue Printer**, integrating Bluetooth printers into your Flutter app is simple and efficient. Enjoy printing directly from your mobile device with just a few lines of code!