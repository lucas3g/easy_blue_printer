import Foundation

public protocol BluetoothRepository {
    func scanDevices() -> [BluetoothDeviceEntity]
    func connectToDevice(address: String) -> Bool
    func disconnectToDevice() -> Bool
    func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool
    func printEmptyLine(callTimes: Int) -> Bool
}