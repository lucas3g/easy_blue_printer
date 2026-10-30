import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BluetoothDevice.parseDevices', () {
    test('separa nome e endereço no formato que as duas plataformas mandam', () {
      final devices = BluetoothDevice.parseDevices(['MTP-II (66:22:B3:01:9F:10)']);

      expect(devices.single.name, 'MTP-II');
      expect(devices.single.address, '66:22:B3:01:9F:10');
    });

    test('nome com parênteses não contamina o endereço', () {
      final devices = BluetoothDevice.parseDevices(['Printer (BLE) (5B1E8C2A-4F7D-4E0B-9C3A-1D2E3F4A5B6C)']);

      expect(devices.single.name, 'Printer (BLE)');
      expect(devices.single.address, '5B1E8C2A-4F7D-4E0B-9C3A-1D2E3F4A5B6C');
    });
  });
}
