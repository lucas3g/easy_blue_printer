import Foundation

public class FeedLineUseCase {
    private let repository: BluetoothRepository

    public init(repository: BluetoothRepository) {
        self.repository = repository
    }

    public func execute(callTimes: Int) -> Bool {
        return repository.printEmptyLine(callTimes: callTimes)
    }
}
