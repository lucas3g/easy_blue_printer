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
      final name = device.substring(0, device.indexOf('('));
      final address = device.substring(device.indexOf('(') + 1, device.length - 1);

      return BluetoothDevice(name: name, address: address);
    }).toList();
  }
}
