import Foundation

// Modulo de injeção de dependência para o aplicativo
public class AppModule {
    // Instâncias do BluetoothDataSource e BluetoothRepository
    private static let bluetoothDataSource = BluetoothDataSource()
    private static let bluetoothRepository: BluetoothRepository = BluetoothRepositoryImpl(dataSource: bluetoothDataSource)
    
    // Casos de uso
    public static let scanDevicesUseCase = ScanDevicesUseCase(repository: bluetoothRepository)
    public static let connectDeviceUseCase = ConnectDeviceUseCase(repository: bluetoothRepository)
    public static let printUseCase = PrintUseCase(repository: bluetoothRepository)
    public static let disconnectDeviceUseCase = DisconnectDeviceUseCase(repository: bluetoothRepository)
    public static let feedLineUseCase = FeedLineUseCase(repository: bluetoothRepository)
}
