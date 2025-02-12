import Foundation
import CoreBluetooth

public class BluetoothDataSource: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var bluetoothManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var connectedSocket: OutputStream?
    private var device: BluetoothDeviceEntity?

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Scan devices
    public func scanDevices() -> [BluetoothDeviceEntity] {
        guard let bluetoothManager = bluetoothManager, bluetoothManager.state == .poweredOn else {
            return []
        }

        bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
        var devices: [BluetoothDeviceEntity] = []

        // Assuming device discovery is handled elsewhere in the delegate method
        return devices
    }

    // Connect to device
    public func connectToDevice(address: String) -> Bool {
        guard let bluetoothManager = bluetoothManager else { return false }

        if let peripheral = findPeripheralByAddress(address) {
            bluetoothManager.stopScan()
            bluetoothManager.connect(peripheral, options: nil)
            return true
        }
        return false
    }

    // Find peripheral by address
    private func findPeripheralByAddress(_ address: String) -> CBPeripheral? {
        // This would ideally return the corresponding peripheral by address.
        // You need to store the discovered peripherals to match by address.
        return nil
    }

    // Delegate method: didDiscover
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = BluetoothDeviceEntity(name: peripheral.name ?? "Unknown", address: peripheral.identifier.uuidString)
        // Add device to list of discovered devices
    }

    // Delegate method: didConnect
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    // Delegate method: didFailToConnect
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Handle failure to connect
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth state is unknown")
        case .resetting:
            print("Bluetooth state is resetting")
        case .unsupported:
            print("Bluetooth is not supported on this device")
        case .unauthorized:
            print("Bluetooth is not authorized")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .poweredOn:
            print("Bluetooth is powered on")
        @unknown default:
            print("A new Bluetooth state was added")
        }
    }

    // Print data
    public func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        guard let socket = connectedSocket else { return false }

        let alignmentData: [UInt8] = getAlignmentData(for: align)
        let boldData: [UInt8] = bold ? [0x1B, 0x47, 0x01] : [0x1B, 0x47, 0x00]
        let fontSizeData: [UInt8] = getFontSizeData(for: size)

        // Write data to socket
        do {
            try socket.write(data: alignmentData)
            try socket.write(data: boldData)
            try socket.write(data: fontSizeData)
            try socket.write(data: [UInt8](data.utf8))
            try socket.write(data: [0x0A]) // New line
            return true
        } catch {
            print("Error printing data: \(error)")
            return false
        }
    }

    // Get alignment data
    private func getAlignmentData(for align: Int) -> [UInt8] {
        switch align {
        case 0: return [0x1B, 0x61, 0x00] // Left align
        case 1: return [0x1B, 0x61, 0x01] // Center align
        case 2: return [0x1B, 0x61, 0x02] // Right align
        default: return []
        }
    }

    // Get font size data
    private func getFontSizeData(for size: Int) -> [UInt8] {
        switch size {
        case 0: return [0x1B, 0x21, 0x03] // Normal size
        case 1: return [0x1B, 0x21, 0x10] // Medium size
        case 2: return [0x1B, 0x21, 0x20] // Large size
        case 3: return [0x1B, 0x21, 0x30] // Huge size
        default: return []
        }
    }

    // Disconnect from device
    public func disconnectFromDevice() -> Bool {
        do {
            if let peripheral = connectedPeripheral {
                bluetoothManager?.cancelPeripheralConnection(peripheral)
            }
            connectedPeripheral = nil
            connectedSocket = nil
            return true
        } catch {
            print("Error disconnecting from device: \(error)")
            return false
        }
    }

    // Print empty line
    public func printEmptyLine(callTimes: Int) -> Bool {
        guard let socket = connectedSocket else { return false }

        do {
            for _ in 0..<callTimes {
                try socket.write(data: [0x0A]) // New line
            }
            return true
        } catch {
            print("Error printing empty line: \(error)")
            return false
        }
    }
}

// Extension for OutputStream to handle data writing
extension OutputStream {
    func write(data: [UInt8]) throws {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        pointer.initialize(from: data, count: data.count)
        self.write(pointer, maxLength: data.count)
        pointer.deallocate()
    }
}
