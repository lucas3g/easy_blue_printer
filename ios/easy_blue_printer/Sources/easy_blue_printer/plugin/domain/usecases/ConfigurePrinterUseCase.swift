import Foundation

public class ConfigurePrinterUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(paperWidth: Int, heatingTime: Int?) {
        repository.configurePrinter(paperWidth: paperWidth, heatingTime: heatingTime)
    }
}
