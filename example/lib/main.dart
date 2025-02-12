import 'dart:async';

import 'package:easy_blue_printer/domain/entities/bluetooth_device.dart';
import 'package:easy_blue_printer/domain/enums/font_size.dart';
import 'package:easy_blue_printer/domain/enums/text_align.dart';
import 'package:easy_blue_printer/easy_blue_printer.dart';
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
  final _easyBluePrinterPlugin = EasyBluePrinter();

  final _devicesStream = StreamController<List<BluetoothDevice>>();

  void _scanDevices() async {
    try {
      final List<BluetoothDevice> devices =
          await _easyBluePrinterPlugin.scanDevices();

      _devicesStream.add([]);

      _devicesStream.add(devices);
    } catch (e) {
      print(e);
    }
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
                stream: _devicesStream.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: const CircularProgressIndicator());
                  }

                  if (snapshot.hasData) {
                    final devices = snapshot.data;

                    return Column(
                      children: devices!.map((device) {
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(
                            device.address +
                                (device.connected ? ' - Connected' : ''),
                          ),
                          onTap: () async {
                            if (device.connected) {
                              final disconnected = await _easyBluePrinterPlugin
                                  .disconnectFromDevice();

                              if (disconnected) {
                                device.setConnected(false);

                                setState(() {});
                              }

                              return;
                            }

                            final connected = await _easyBluePrinterPlugin
                                .connectToDevice(device);

                            if (connected) {
                              device.setConnected(true);

                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    );
                  }

                  return const SizedBox();
                },
              ),
              ElevatedButton(
                onPressed: _scanDevices,
                child: const Text('Scan Devices'),
              ),
              SizedBox(
                height: 20,
              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
