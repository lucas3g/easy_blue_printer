class BluetoothDevice {
  final String name;
  final String address;
  bool connected = false;

  void setConnected(bool value) {
    connected = value;
  }

  BluetoothDevice({required this.name, required this.address});

  @override
  String toString() {
    return 'BluetoothDevice(name: $name, address: $address)';
  }

  static List<BluetoothDevice> parseDevices(List<String> deviceStrings) {
    return deviceStrings.map((device) {
      // O endereço é sempre o último par de parênteses. Cortar no primeiro
      // fazia "Printer (BLE) (XX)" virar o endereço "BLE) (XX", e a conexão
      // falhava com a impressora na lista.
      final open = device.lastIndexOf('(');
      final name = device.substring(0, open).trim();
      final address = device.substring(open + 1, device.length - 1);

      return BluetoothDevice(name: name, address: address);
    }).toList();
  }
}
