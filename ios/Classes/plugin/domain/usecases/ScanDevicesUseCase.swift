import Foundation

public class ScanDevicesUseCase {
    private var repository: BluetoothRepository

    init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute() -> [BluetoothDeviceEntity] {
        return repository.scanDevices()
    }
}