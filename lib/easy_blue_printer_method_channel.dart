import 'package:easy_blue_printer/domain/entities/bluetooth_device.dart';
import 'package:easy_blue_printer/domain/enums/font_size.dart';
import 'package:easy_blue_printer/domain/enums/text_align.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'easy_blue_printer_platform_interface.dart';

/// An implementation of [EasyBluePrinterPlatform] that uses method channels.
class MethodChannelEasyBluePrinter extends EasyBluePrinterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('easy_blue_printer');

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async {
    final rawDevices = await methodChannel.invokeMethod('getPairedDevices');

    return BluetoothDevice.parseDevices(rawDevices.cast<String>());
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await methodChannel.invokeMethod('connectToDevice', {
      'address': device.address,
    });
  }

  @override
  Future<bool> disconnectFromDevice() async {
    return await methodChannel.invokeMethod('disconnectFromDevice');
  }

  @override
  Future<bool> printData(
      {required String data,
      required FS fontSize,
      required TA textAlign,
      required bool bold}) async {
    return await methodChannel.invokeMethod('printData', {
      'data': data,
      'fontSize': fontSize.index,
      'textAlign': textAlign.index,
      'bold': bold,
    });
  }

  @override
  Future<void> printEmptyLine({required int callTimes}) async {
    await methodChannel.invokeMethod('printEmptyLine', {
      'callTimes': callTimes,
    });
  }

  @override
  Future<bool> isConnected() async {
    return await methodChannel.invokeMethod('isConnected');
  }

  @override
  Future<bool> printImage(
      {required Uint8List bytes, required TA textAlign}) async {
    return await methodChannel.invokeMethod('printImage', {
      'data': bytes,
      'textAlign': textAlign.index,
    });
  }
}
