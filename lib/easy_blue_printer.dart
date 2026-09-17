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

  final Queue<_PrintJob<dynamic>> _queue = Queue();
  bool _isProcessing = false;

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final printJob = _PrintJob<T>(job);
    _queue.add(printJob);
    _processQueue();
    return printJob.future;
  }

  /// Runs the queued jobs and completes their futures only once the bytes they
  /// produced have actually left for the printer.
  ///
  /// A job does not print: it appends ESC/POS bytes to a buffer on the native
  /// side, and only [EasyBluePrinterPlatform.commitPrint] writes that buffer to
  /// the socket. Completing a job's future when the job itself returned made
  /// `await printImage(...)` resolve with the whole raster still in memory —
  /// callers announced the document as printed before the first byte was sent,
  /// and a socket error raised during the commit landed on a future nobody was
  /// listening to.
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    // do-while ensures that if new jobs arrive while commitPrint is running
    // (e.g. user code awaits printData and immediately enqueues printEmptyLine),
    // those jobs are picked up instead of staying stuck in the queue forever.
    do {
      final buffered = <_PrintJob<dynamic>>[];
      while (_queue.isNotEmpty) {
        final job = _queue.removeFirst();
        try {
          await job.run();
          buffered.add(job);
        } catch (e, st) {
          // Nothing of this job reached the buffer, so the commit says nothing
          // about it: fail this one alone and keep printing the rest.
          job.completeError(e, st);
        }
      }
      // When the queue empties, flush any buffered bytes that were not yet
      // sent (e.g. text-only receipts with no printEmptyLine at the end).
      try {
        await EasyBluePrinterPlatform.instance.commitPrint();
        for (final job in buffered) {
          job.complete();
        }
      } catch (e, st) {
        // The bytes of every buffered job went out in this same stream, so the
        // failure belongs to all of them.
        for (final job in buffered) {
          job.completeError(e, st);
        }
      }
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
    return _enqueue(
      () => EasyBluePrinterPlatform.instance.printData(data: data, fontSize: fontSize, textAlign: textAlign, bold: bold),
    );
  }

  Future<void> printEmptyLine({required int callTimes}) {
    // The job yields a value the queue can carry around: a `void` job would
    // leave _PrintJob with nothing to hand back to its completer.
    return _enqueue<bool>(() async {
      await EasyBluePrinterPlatform.instance.printEmptyLine(callTimes: callTimes);
      return true;
    });
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

/// A queued call, kept apart from the future handed to the caller: the value is
/// produced when the job runs, but only delivered after the commit that sent
/// its bytes.
class _PrintJob<T> {
  _PrintJob(this._task);

  final Future<T> Function() _task;
  final Completer<T> _completer = Completer<T>();

  late final T _value;

  Future<T> get future => _completer.future;

  Future<void> run() async => _value = await _task();

  void complete() => _completer.complete(_value);

  void completeError(Object error, StackTrace stackTrace) => _completer.completeError(error, stackTrace);
}
