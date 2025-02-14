import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:easy_blue_printer_example/bluetooth_controller.dart';
import 'package:flutter/material.dart';

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
    bluetoothController.startScan(); // Inicia o scan ao carregar a tela
  }

  @override
  void dispose() {
    bluetoothController.stopScan(); // Para o scan quando a tela for descartada
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
