# Easy Blue Printer

[![pub package](https://img.shields.io/pub/v/easy_blue_printer.svg)](https://pub.dev/packages/easy_blue_printer)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)]()

A Flutter plugin for Bluetooth thermal printers. Scan, connect, and print text or images with just a few lines of code.

**[English](#english)** | **[Portugues](#portugues)**

---

# English

## Features

- Scan nearby Bluetooth devices
- Connect and disconnect from printers
- Print text with font size, alignment, and bold options
- Print images from bytes
- Print empty lines (paper feed)
- Check connection status
- Works on **Android** and **iOS**

## Supported Platforms

| Platform | Minimum Version |
|----------|----------------|
| Android  | SDK 21 (5.0)   |
| iOS      | 12.0           |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  easy_blue_printer: ^latest_version
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <application ...>
```

> On Android 12+ the plugin automatically requests runtime permissions.

### iOS

Add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>
```

## Quick Start

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';

final printer = EasyBluePrinter.instance;

// 1. Scan for devices
final devices = await printer.getPairedDevices();

// 2. Connect to a device
final connected = await printer.connectToDevice(devices.first);

// 3. Print text
await printer.printData(
  data: 'Hello, World!',
  fontSize: FS.medium,
  textAlign: TA.center,
  bold: true,
);

// 4. Feed paper
await printer.printEmptyLine(callTimes: 5);

// 5. Disconnect
await printer.disconnectFromDevice();
```

## API Reference

### `EasyBluePrinter.instance`

Singleton instance. Use this to access all methods.

---

### `getPairedDevices()`

Scans and returns a list of available Bluetooth devices.

```dart
Future<List<BluetoothDevice>> getPairedDevices()
```

**Returns:** List of `BluetoothDevice` objects with `name` and `address` properties.

---

### `connectToDevice(device)`

Connects to a Bluetooth printer.

```dart
Future<bool> connectToDevice(BluetoothDevice device)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `device` | `BluetoothDevice` | Device returned by `getPairedDevices()` |

**Returns:** `true` if connected successfully.

---

### `disconnectFromDevice()`

Disconnects from the current printer.

```dart
Future<bool> disconnectFromDevice()
```

**Returns:** `true` if disconnected successfully.

---

### `printData(...)`

Prints formatted text.

```dart
Future<bool> printData({
  required String data,
  required FS fontSize,
  required TA textAlign,
  required bool bold,
})
```

| Parameter   | Type   | Description              |
|-------------|--------|--------------------------|
| `data`      | `String` | Text to print           |
| `fontSize`  | `FS`     | Font size (see Enums)   |
| `textAlign` | `TA`     | Alignment (see Enums)   |
| `bold`      | `bool`   | Enable bold text        |

**Returns:** `true` if printed successfully.

---

### `printEmptyLine(callTimes)`

Feeds paper by printing empty lines.

```dart
Future<void> printEmptyLine({required int callTimes})
```

| Parameter   | Type  | Description                  |
|-------------|-------|------------------------------|
| `callTimes` | `int` | Number of empty lines to print |

---

### `printImage(bytes, textAlign)`

Prints an image on the thermal printer.

```dart
Future<bool> printImage({
  required Uint8List bytes,
  required TA textAlign,
})
```

| Parameter   | Type        | Description                   |
|-------------|-------------|-------------------------------|
| `bytes`     | `Uint8List` | Image data as bytes           |
| `textAlign` | `TA`        | Image alignment (see Enums)   |

**Returns:** `true` if printed successfully.

**Example — print from assets:**

```dart
import 'package:flutter/services.dart';

final byteData = await rootBundle.load('assets/images/logo.png');
final bytes = byteData.buffer.asUint8List();

await printer.printImage(bytes: bytes, textAlign: TA.center);
```

---

### `isConnected()`

Checks if a printer is currently connected.

```dart
Future<bool> isConnected()
```

**Returns:** `true` if connected.

---

## Enums

### `FS` — Font Size

| Value    | Description     |
|----------|-----------------|
| `FS.normal` | Normal size  |
| `FS.medium` | Medium size  |
| `FS.large`  | Large size   |
| `FS.huge`   | Extra large  |

### `TA` — Text Alignment

| Value      | Description   |
|------------|---------------|
| `TA.left`   | Left align   |
| `TA.center` | Center align |
| `TA.right`  | Right align  |

## Complete Example

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const PrinterPage());
  }
}

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final printer = EasyBluePrinter.instance;

  List<BluetoothDevice> devices = [];
  bool isConnected = false;
  bool isLoading = false;

  Future<void> scan() async {
    setState(() => isLoading = true);
    devices = await printer.getPairedDevices();
    setState(() => isLoading = false);
  }

  Future<void> connect(BluetoothDevice device) async {
    setState(() => isLoading = true);
    isConnected = await printer.connectToDevice(device);
    setState(() => isLoading = false);
  }

  Future<void> printReceipt() async {
    await printer.printData(
      data: 'My Store',
      fontSize: FS.large,
      textAlign: TA.center,
      bold: true,
    );
    await printer.printData(
      data: '------------------------',
      fontSize: FS.normal,
      textAlign: TA.center,
      bold: false,
    );
    await printer.printData(
      data: 'Item 1          R$ 10.00',
      fontSize: FS.normal,
      textAlign: TA.left,
      bold: false,
    );
    await printer.printData(
      data: 'Item 2          R$ 25.00',
      fontSize: FS.normal,
      textAlign: TA.left,
      bold: false,
    );
    await printer.printData(
      data: '------------------------',
      fontSize: FS.normal,
      textAlign: TA.center,
      bold: false,
    );
    await printer.printData(
      data: 'TOTAL           R$ 35.00',
      fontSize: FS.medium,
      textAlign: TA.left,
      bold: true,
    );
    await printer.printEmptyLine(callTimes: 5);
  }

  Future<void> disconnect() async {
    await printer.disconnectFromDevice();
    setState(() => isConnected = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Example')),
      body: Column(
        children: [
          // Scan button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoading ? null : scan,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Scan Devices'),
            ),
          ),

          // Device list
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  onTap: () => connect(device),
                );
              },
            ),
          ),

          // Print and disconnect buttons
          if (isConnected) ...[
            ElevatedButton(
              onPressed: printReceipt,
              child: const Text('Print Receipt'),
            ),
            TextButton(
              onPressed: disconnect,
              child: const Text('Disconnect'),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Feel free to open a PR or report issues on the [repository](https://github.com/lucas3g/easy_blue_printer).

## License

This project is distributed under the MIT license. See the [LICENSE](LICENSE) file for details.

---

# Portugues

## Funcionalidades

- Escanear dispositivos Bluetooth
- Conectar e desconectar de impressoras
- Imprimir texto com tamanho de fonte, alinhamento e negrito
- Imprimir imagens a partir de bytes
- Imprimir linhas em branco (alimentar papel)
- Verificar status da conexao
- Funciona no **Android** e **iOS**

## Plataformas Suportadas

| Plataforma | Versao Minima  |
|------------|----------------|
| Android    | SDK 21 (5.0)   |
| iOS        | 12.0           |

## Instalacao

Adicione no seu `pubspec.yaml`:

```yaml
dependencies:
  easy_blue_printer: ^latest_version
```

Depois execute:

```bash
flutter pub get
```

## Configuracao por Plataforma

### Android

Adicione estas permissoes no `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <application ...>
```

> No Android 12+ o plugin solicita as permissoes automaticamente em tempo de execucao.

### iOS

Adicione estas chaves no `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Este app precisa do Bluetooth para conectar a impressoras</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Este app precisa do Bluetooth para conectar a impressoras</string>
```

## Inicio Rapido

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';

final printer = EasyBluePrinter.instance;

// 1. Escanear dispositivos
final devices = await printer.getPairedDevices();

// 2. Conectar a um dispositivo
final connected = await printer.connectToDevice(devices.first);

// 3. Imprimir texto
await printer.printData(
  data: 'Ola, Mundo!',
  fontSize: FS.medium,
  textAlign: TA.center,
  bold: true,
);

// 4. Alimentar papel
await printer.printEmptyLine(callTimes: 5);

// 5. Desconectar
await printer.disconnectFromDevice();
```

## Referencia da API

### `EasyBluePrinter.instance`

Instancia singleton. Use para acessar todos os metodos.

---

### `getPairedDevices()`

Escaneia e retorna uma lista de dispositivos Bluetooth disponiveis.

```dart
Future<List<BluetoothDevice>> getPairedDevices()
```

**Retorno:** Lista de objetos `BluetoothDevice` com as propriedades `name` e `address`.

---

### `connectToDevice(device)`

Conecta a uma impressora Bluetooth.

```dart
Future<bool> connectToDevice(BluetoothDevice device)
```

| Parametro | Tipo | Descricao |
|-----------|------|-----------|
| `device` | `BluetoothDevice` | Dispositivo retornado por `getPairedDevices()` |

**Retorno:** `true` se conectou com sucesso.

---

### `disconnectFromDevice()`

Desconecta da impressora atual.

```dart
Future<bool> disconnectFromDevice()
```

**Retorno:** `true` se desconectou com sucesso.

---

### `printData(...)`

Imprime texto formatado.

```dart
Future<bool> printData({
  required String data,
  required FS fontSize,
  required TA textAlign,
  required bool bold,
})
```

| Parametro   | Tipo     | Descricao                    |
|-------------|----------|------------------------------|
| `data`      | `String` | Texto para imprimir          |
| `fontSize`  | `FS`     | Tamanho da fonte (ver Enums) |
| `textAlign` | `TA`     | Alinhamento (ver Enums)      |
| `bold`      | `bool`   | Ativar negrito               |

**Retorno:** `true` se imprimiu com sucesso.

---

### `printEmptyLine(callTimes)`

Alimenta o papel imprimindo linhas em branco.

```dart
Future<void> printEmptyLine({required int callTimes})
```

| Parametro   | Tipo  | Descricao                        |
|-------------|-------|----------------------------------|
| `callTimes` | `int` | Quantidade de linhas em branco   |

---

### `printImage(bytes, textAlign)`

Imprime uma imagem na impressora termica.

```dart
Future<bool> printImage({
  required Uint8List bytes,
  required TA textAlign,
})
```

| Parametro   | Tipo        | Descricao                         |
|-------------|-------------|-----------------------------------|
| `bytes`     | `Uint8List` | Dados da imagem em bytes          |
| `textAlign` | `TA`        | Alinhamento da imagem (ver Enums) |

**Retorno:** `true` se imprimiu com sucesso.

**Exemplo — imprimir dos assets:**

```dart
import 'package:flutter/services.dart';

final byteData = await rootBundle.load('assets/images/logo.png');
final bytes = byteData.buffer.asUint8List();

await printer.printImage(bytes: bytes, textAlign: TA.center);
```

---

### `isConnected()`

Verifica se uma impressora esta conectada.

```dart
Future<bool> isConnected()
```

**Retorno:** `true` se estiver conectado.

---

## Enums

### `FS` — Tamanho da Fonte

| Valor       | Descricao       |
|-------------|-----------------|
| `FS.normal` | Tamanho normal  |
| `FS.medium` | Tamanho medio   |
| `FS.large`  | Tamanho grande  |
| `FS.huge`   | Tamanho extra grande |

### `TA` — Alinhamento do Texto

| Valor       | Descricao            |
|-------------|----------------------|
| `TA.left`   | Alinhar a esquerda   |
| `TA.center` | Centralizar          |
| `TA.right`  | Alinhar a direita    |

## Exemplo Completo

```dart
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const PrinterPage());
  }
}

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final printer = EasyBluePrinter.instance;

  List<BluetoothDevice> devices = [];
  bool isConnected = false;
  bool isLoading = false;

  Future<void> scan() async {
    setState(() => isLoading = true);
    devices = await printer.getPairedDevices();
    setState(() => isLoading = false);
  }

  Future<void> connect(BluetoothDevice device) async {
    setState(() => isLoading = true);
    isConnected = await printer.connectToDevice(device);
    setState(() => isLoading = false);
  }

  Future<void> printReceipt() async {
    await printer.printData(
      data: 'Minha Loja',
      fontSize: FS.large,
      textAlign: TA.center,
      bold: true,
    );
    await printer.printData(
      data: '------------------------',
      fontSize: FS.normal,
      textAlign: TA.center,
      bold: false,
    );
    await printer.printData(
      data: 'Item 1          R\$ 10,00',
      fontSize: FS.normal,
      textAlign: TA.left,
      bold: false,
    );
    await printer.printData(
      data: 'Item 2          R\$ 25,00',
      fontSize: FS.normal,
      textAlign: TA.left,
      bold: false,
    );
    await printer.printData(
      data: '------------------------',
      fontSize: FS.normal,
      textAlign: TA.center,
      bold: false,
    );
    await printer.printData(
      data: 'TOTAL           R\$ 35,00',
      fontSize: FS.medium,
      textAlign: TA.left,
      bold: true,
    );
    await printer.printEmptyLine(callTimes: 5);
  }

  Future<void> disconnect() async {
    await printer.disconnectFromDevice();
    setState(() => isConnected = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplo Impressora')),
      body: Column(
        children: [
          // Botao de escanear
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoading ? null : scan,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Escanear Dispositivos'),
            ),
          ),

          // Lista de dispositivos
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  onTap: () => connect(device),
                );
              },
            ),
          ),

          // Botoes de imprimir e desconectar
          if (isConnected) ...[
            ElevatedButton(
              onPressed: printReceipt,
              child: const Text('Imprimir Recibo'),
            ),
            TextButton(
              onPressed: disconnect,
              child: const Text('Desconectar'),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
```

## Contribuindo

Contribuicoes sao bem-vindas! Sinta-se a vontade para abrir um PR ou reportar problemas no [repositorio](https://github.com/lucas3g/easy_blue_printer).

## Licenca

Este projeto e distribuido sob a licenca MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
