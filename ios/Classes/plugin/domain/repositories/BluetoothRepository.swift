import Foundation

public protocol BluetoothRepository {
    func scanDevices() -> [BluetoothDeviceEntity]
}