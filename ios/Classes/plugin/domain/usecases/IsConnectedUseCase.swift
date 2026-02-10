import Foundation

public class IsConnectedUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute() -> Bool {
        return repository.isConnected()
    }
}
