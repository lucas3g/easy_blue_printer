import 'dart:async';

import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:flutter/services.dart';

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
    try {
      final connected = await _easyBluePrinterPlugin.connectToDevice(device);

      device.setConnected(connected);

      return connected;
    } catch (e) {
      print(e);

      return false;
    }
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
        await rootBundle.load(path).then((value) => value.buffer.asUint8List());

    return await _easyBluePrinterPlugin.printImage(
        bytes: bytes, textAlign: textAlign);
  }
}
