import Foundation

public class PrintImageUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(data: Data, align: Int) -> Bool {
        return repository.printImage(data: data, align: align)
    }
}
