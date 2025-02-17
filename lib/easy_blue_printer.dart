library;

import 'dart:typed_data';

import 'package:easy_blue_printer/domain/entities/bluetooth_device.dart';
import 'package:easy_blue_printer/domain/enums/font_size.dart';
import 'package:easy_blue_printer/domain/enums/text_align.dart';

import 'easy_blue_printer_platform_interface.dart';

export 'domain/entities/bluetooth_device.dart';
export 'domain/enums/font_size.dart';
export 'domain/enums/text_align.dart';

class EasyBluePrinter {
  EasyBluePrinter._() {
    requestBluetoothPermissions();
  }

  static final EasyBluePrinter _instance = EasyBluePrinter._();

  static EasyBluePrinter get instance => _instance;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await EasyBluePrinterPlatform.instance.getPairedDevices();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await EasyBluePrinterPlatform.instance.connectToDevice(device);
  }

  Future<bool> disconnectFromDevice() async {
    return await EasyBluePrinterPlatform.instance.disconnectFromDevice();
  }

  Future<bool> printData({
    required String data,
    required FS fontSize,
    required TA textAlign,
    required bool bold,
  }) async {
    return await EasyBluePrinterPlatform.instance.printData(
      data: data,
      fontSize: fontSize,
      textAlign: textAlign,
      bold: bold,
    );
  }

  Future<void> printEmptyLine({required int callTimes}) async {
    await EasyBluePrinterPlatform.instance.printEmptyLine(callTimes: callTimes);
  }

  Future<bool> isConnected() async {
    return await EasyBluePrinterPlatform.instance.isConnected();
  }

  Future<bool> printImage(
      {required Uint8List bytes, required TA textAlign}) async {
    return await EasyBluePrinterPlatform.instance.printImage(
      bytes: bytes,
      textAlign: textAlign,
    );
  }

  Future<void> requestBluetoothPermissions() async {
    await EasyBluePrinterPlatform.instance.requestBluetoothPermissions();
  }
}
