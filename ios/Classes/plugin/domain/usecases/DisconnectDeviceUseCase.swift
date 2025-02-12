import Foundation

public class DisconnectDeviceUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute() -> Bool {
        return repository.disconnectToDevice()
    }
}
