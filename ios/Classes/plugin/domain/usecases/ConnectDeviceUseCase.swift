import Foundation

public class ConnectDeviceUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(address: String) -> Bool {
        return repository.connectToDevice(address: address)
    }
}
