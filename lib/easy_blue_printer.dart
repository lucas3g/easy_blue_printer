library;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_blue_printer/domain/entities/bluetooth_device.dart';
import 'package:easy_blue_printer/domain/entities/paper_config.dart';
import 'package:easy_blue_printer/domain/enums/font_size.dart';
import 'package:easy_blue_printer/domain/enums/text_align.dart';

import 'easy_blue_printer_platform_interface.dart';

export 'domain/entities/bluetooth_device.dart';
export 'domain/entities/paper_config.dart';
export 'domain/enums/font_size.dart';
export 'domain/enums/text_align.dart';

class EasyBluePrinter {
  EasyBluePrinter._() {
    if (Platform.isAndroid) requestBluetoothPermissions();
  }

  static final EasyBluePrinter _instance = EasyBluePrinter._();

  static EasyBluePrinter get instance => _instance;

  final Queue<_PrintJob> _queue = Queue();
  bool _isProcessing = false;

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    _queue.add(_PrintJob(() async {
      try {
        completer.complete(await job());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }));
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    // do-while ensures that if new jobs arrive while commitPrint is running
    // (e.g. user code awaits printData and immediately enqueues printEmptyLine),
    // those jobs are picked up instead of staying stuck in the queue forever.
    do {
      while (_queue.isNotEmpty) {
        await _queue.removeFirst().run();
      }
      // When the queue empties, flush any buffered bytes that were not yet
      // sent (e.g. text-only receipts with no printEmptyLine at the end).
      await EasyBluePrinterPlatform.instance.commitPrint();
    } while (_queue.isNotEmpty);
    _isProcessing = false;
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await EasyBluePrinterPlatform.instance.getPairedDevices();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await EasyBluePrinterPlatform.instance.connectToDevice(device);
  }

  Future<bool> disconnectFromDevice() async {
    return await EasyBluePrinterPlatform.instance.disconnectFromDevice();
  }

  Future<bool> printData({required String data, required FS fontSize, required TA textAlign, required bool bold}) {
    return _enqueue(() => EasyBluePrinterPlatform.instance.printData(
          data: data,
          fontSize: fontSize,
          textAlign: textAlign,
          bold: bold,
        ));
  }

  Future<void> printEmptyLine({required int callTimes}) {
    return _enqueue(() => EasyBluePrinterPlatform.instance.printEmptyLine(callTimes: callTimes));
  }

  Future<bool> isConnected() async {
    return await EasyBluePrinterPlatform.instance.isConnected();
  }

  Future<bool> printImage({required Uint8List bytes, required TA textAlign}) {
    return _enqueue(() => EasyBluePrinterPlatform.instance.printImage(bytes: bytes, textAlign: textAlign));
  }

  Future<void> requestBluetoothPermissions() async {
    await EasyBluePrinterPlatform.instance.requestBluetoothPermissions();
  }

  Future<void> configurePrinter(PaperConfig config) async {
    await EasyBluePrinterPlatform.instance.configurePrinter(config);
  }
}

class _PrintJob {
  final Future<void> Function() run;
  const _PrintJob(this.run);
}
