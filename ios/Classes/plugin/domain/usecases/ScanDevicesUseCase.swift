import Foundation

public class ScanDevicesUseCase {
    private var repository: BluetoothRepository

    init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(completion: @escaping ([BluetoothDeviceEntity]) -> Void) {
        repository.scanDevices { devices in
            completion(devices)
        }
    }
}
