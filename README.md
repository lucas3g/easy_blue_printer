# Easy Blue Printer

## Descrição
O `easy_blue_printer` é um pacote Flutter que facilita a conexão com impressoras Bluetooth para impressão de textos formatados. Este exemplo demonstra como utilizar o pacote para listar dispositivos Bluetooth pareados, conectar-se a uma impressora e imprimir textos.

---

## Instalação
Adicione a dependência ao seu arquivo `pubspec.yaml`:

```yaml
dependencies:
  easy_blue_printer: latest_version
```

Substitua `latest_version` pela versão mais recente do pacote.

---

## Uso

### 1. Configurando o Bluetooth Controller
Crie uma classe `BluetoothController` para gerenciar a conexão Bluetooth e a impressão.

```dart
import 'dart:async';
import 'package:easy_blue_printer/easy_blue_printer.dart';

class BluetoothController {
  final EasyBluePrinter _easyBluePrinterPlugin = EasyBluePrinter();
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
}
```

---

### 2. Criando a Interface do Usuário
Agora, criamos um aplicativo Flutter que permite listar dispositivos Bluetooth, conectar-se a uma impressora e enviar textos para impressão.

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
                    return Text('Nenhum dispositivo encontrado');
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

---

## Funcionalidades
- Listar dispositivos Bluetooth pareados.
- Conectar-se a uma impressora Bluetooth.
- Enviar textos para impressão com diferentes tamanhos e alinhamentos.
- Imprimir linhas em branco.
- Desconectar-se da impressora.

---

## Contribuição
Se você deseja contribuir com melhorias para o `easy_blue_printer`, fique à vontade para abrir um PR ou relatar problemas no repositório.

---

## Licença
Este projeto é distribuído sob a licença MIT. Para mais detalhes, consulte o arquivo `LICENSE`.

