import 'package:easy_blue_printer/domain/entities/bluetooth_device.dart';
import 'package:easy_blue_printer/domain/enums/font_size.dart';
import 'package:easy_blue_printer/domain/enums/text_align.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'easy_blue_printer_method_channel.dart';

abstract class EasyBluePrinterPlatform extends PlatformInterface {
  /// Constructs a EasyBluePrinterPlatform.
  EasyBluePrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasyBluePrinterPlatform _instance = MethodChannelEasyBluePrinter();

  /// The default instance of [EasyBluePrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelEasyBluePrinter].
  static EasyBluePrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EasyBluePrinterPlatform] when
  /// they register themselves.
  static set instance(EasyBluePrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<BluetoothDevice>> scanDevices();

  Future<bool> connectToDevice(BluetoothDevice device);

  Future<bool> disconnectFromDevice();

  Future<bool> printData({
    required String data,
    required FS fontSize,
    required TA textAlign,
    required bool bold,
  });

  Future<void> printEmptyLine({required int callTimes});

  Future<bool> isConnected();
}
