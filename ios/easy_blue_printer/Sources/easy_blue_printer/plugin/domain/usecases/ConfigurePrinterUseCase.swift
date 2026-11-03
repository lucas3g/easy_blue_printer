import Foundation

public class ConfigurePrinterUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(paperWidth: Int, heatingTime: Int?, linesPerSecond: Int?) {
        repository.configurePrinter(paperWidth: paperWidth, heatingTime: heatingTime, linesPerSecond: linesPerSecond)
    }
}
