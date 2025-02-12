import Foundation

public class PrintUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        return repository.printData(data: data, size: size, align: align, bold: bold)
    }
}
