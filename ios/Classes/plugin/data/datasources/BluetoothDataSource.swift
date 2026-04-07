import Foundation
import CoreBluetooth
import UIKit

public class BluetoothDataSource: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var bluetoothManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var writableCharacteristic: CBCharacteristic?
    private var discoveredDevices: [BluetoothDeviceEntity] = []
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var scanCompletion: (([BluetoothDeviceEntity]) -> Void)?
    private var connectionSemaphore: DispatchSemaphore?
    private var pendingServiceCount: Int = 0
    private let bluetoothQueue = DispatchQueue(label: "com.easy_blue_printer.bluetooth")
    private var managerReady = false
    private var pendingScanCompletion: (([BluetoothDeviceEntity]) -> Void)?
    private var paperWidth: Int = 384

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
    }

    // MARK: - Public methods

    public func scanDevices(completion: @escaping ([BluetoothDeviceEntity]) -> Void) {
        bluetoothQueue.async { [weak self] in
            guard let self = self,
                  let bluetoothManager = self.bluetoothManager else {
                completion([])
                return
            }

            if !self.managerReady {
                self.pendingScanCompletion = completion
                return
            }

            guard bluetoothManager.state == .poweredOn else {
                completion([])
                return
            }

            self.startScan(bluetoothManager: bluetoothManager, completion: completion)
        }
    }

    private func startScan(bluetoothManager: CBCentralManager, completion: @escaping ([BluetoothDeviceEntity]) -> Void) {
        self.discoveredDevices.removeAll()
        self.discoveredPeripherals.removeAll()
        self.scanCompletion = completion
        bluetoothManager.scanForPeripherals(withServices: nil, options: nil)

        self.bluetoothQueue.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.bluetoothManager?.stopScan()

            if let connected = self.connectedPeripheral,
               let name = connected.name,
               !name.isEmpty {
                let address = connected.identifier.uuidString
                if self.discoveredPeripherals[address] == nil {
                    self.discoveredPeripherals[address] = connected
                    self.discoveredDevices.insert(BluetoothDeviceEntity(name: name, address: address), at: 0)
                }
            }

            self.scanCompletion?(self.discoveredDevices)
            self.scanCompletion = nil
        }
    }

    public func connectToDevice(address: String) -> Bool {
        guard let bluetoothManager = bluetoothManager else { return false }

        guard let peripheral = discoveredPeripherals[address] else { return false }

        bluetoothManager.stopScan()
        writableCharacteristic = nil
        connectionSemaphore = DispatchSemaphore(value: 0)

        bluetoothManager.connect(peripheral, options: nil)

        let result = connectionSemaphore?.wait(timeout: .now() + 10)
        connectionSemaphore = nil

        return result == .success && writableCharacteristic != nil
    }

    public func disconnectFromDevice() -> Bool {
        if let peripheral = connectedPeripheral {
            bluetoothManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        writableCharacteristic = nil
        return true
    }

    public func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        var buffer = Data()
        buffer.append(contentsOf: getAlignmentData(for: align))
        buffer.append(contentsOf: bold ? [0x1B, 0x47, 0x01] : [0x1B, 0x47, 0x00])
        buffer.append(contentsOf: getFontSizeData(for: size))
        buffer.append(data.data(using: .utf8) ?? Data())
        buffer.append(contentsOf: [0x0A])
        return writeData(buffer)
    }

    public func printEmptyLine(callTimes: Int) -> Bool {
        var buffer = Data()
        for _ in 0..<callTimes {
            buffer.append(contentsOf: [0x0A])
        }
        return writeData(buffer)
    }

    public func isConnected() -> Bool {
        return connectedPeripheral != nil
            && connectedPeripheral?.state == .connected
            && writableCharacteristic != nil
    }

    public func configurePrinter(paperWidth: Int) {
        self.paperWidth = paperWidth
    }

    public func printImage(data: Data, align: Int) -> Bool {
        guard let image = UIImage(data: data) else { return false }

        guard let scaledImage = Utils.scaleImage(image, toWidth: paperWidth) else { return false }
        guard let command = Utils.decodeBitmap(scaledImage) else { return false }

        var buffer = Data()
        buffer.append(contentsOf: getAlignmentData(for: align))
        buffer.append(command)

        let imageResult = writeImageData(buffer)

        // Wait for the printer to finish processing the image
        Thread.sleep(forTimeInterval: 0.2)

        // Feed empty lines for paper tear-off
        _ = writeData(Data([0x0A, 0x0A, 0x0A, 0x0A]))

        // Reset printer to text mode after image
        let resetCommand = Data([0x1B, 0x40])
        _ = writeData(resetCommand)

        return imageResult
    }

    // MARK: - Private helpers

    private func writeImageData(_ data: Data) -> Bool {
        guard let peripheral = connectedPeripheral,
              let characteristic = writableCharacteristic else { return false }

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        let mtu = peripheral.maximumWriteValueLength(for: writeType)
        let chunkSize = max(mtu, 20)
        var offset = 0

        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)

            peripheral.writeValue(chunk, for: characteristic, type: writeType)
            Thread.sleep(forTimeInterval: 0.02)

            offset = end
        }
        return true
    }

    private func writeData(_ data: Data) -> Bool {
        guard let peripheral = connectedPeripheral,
              let characteristic = writableCharacteristic else { return false }

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        let mtu = peripheral.maximumWriteValueLength(for: writeType)
        let chunkSize = max(mtu, 20)
        var offset = 0

        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)

            peripheral.writeValue(chunk, for: characteristic, type: writeType)
            Thread.sleep(forTimeInterval: 0.01)

            offset = end
        }
        return true
    }

    private func getAlignmentData(for align: Int) -> [UInt8] {
        switch align {
        case 0: return [0x1B, 0x61, 0x00]
        case 1: return [0x1B, 0x61, 0x01]
        case 2: return [0x1B, 0x61, 0x02]
        default: return []
        }
    }

    private func getFontSizeData(for size: Int) -> [UInt8] {
        switch size {
        case 0: return [0x1B, 0x21, 0x03]
        case 1: return [0x1B, 0x21, 0x08]
        case 2: return [0x1B, 0x21, 0x10]
        case 3: return [0x1B, 0x21, 0x30]
        default: return []
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            managerReady = true
            if let pending = pendingScanCompletion {
                pendingScanCompletion = nil
                startScan(bluetoothManager: central, completion: pending)
            }
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is not authorized")
        case .unsupported:
            print("Bluetooth is not supported on this device")
        case .resetting:
            print("Bluetooth state is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("A new Bluetooth state was added")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty, name != "Unknown" else { return }

        let address = peripheral.identifier.uuidString

        if discoveredPeripherals[address] == nil {
            discoveredPeripherals[address] = peripheral
            discoveredDevices.append(BluetoothDeviceEntity(name: name, address: address))
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionSemaphore?.signal()
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        writableCharacteristic = nil
    }

    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, !services.isEmpty else {
            connectionSemaphore?.signal()
            return
        }

        pendingServiceCount = services.count
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if writableCharacteristic == nil, let characteristics = service.characteristics {
            let knownCharUUIDs: [CBUUID] = [
                CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
                CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"),
            ]

            for char in characteristics {
                if knownCharUUIDs.contains(char.uuid) &&
                    (char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse)) {
                    writableCharacteristic = char
                    break
                }
            }

            if writableCharacteristic == nil {
                for char in characteristics {
                    if char.properties.contains(.writeWithoutResponse) || char.properties.contains(.write) {
                        writableCharacteristic = char
                        break
                    }
                }
            }
        }

        pendingServiceCount -= 1
        if pendingServiceCount <= 0 {
            connectionSemaphore?.signal()
        }
    }
}
