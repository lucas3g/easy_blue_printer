import Foundation

public class BluetoothDeviceEntity {
    public var name: String
    public var address: String

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}