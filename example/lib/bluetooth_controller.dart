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
