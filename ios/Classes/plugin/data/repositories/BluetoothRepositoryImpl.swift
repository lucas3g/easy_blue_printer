import Foundation

// Implementação do repositório Bluetooth
public class BluetoothRepositoryImpl: BluetoothRepository {
    private let dataSource: BluetoothDataSource

    // Inicializador
    public init(dataSource: BluetoothDataSource) {
        self.dataSource = dataSource
    }

    // Escanear e retornar dispositivos Bluetooth disponíveis
    public func scanDevices() -> [BluetoothDeviceEntity] {
        return dataSource.scanDevices()
    }

    // Conectar ao dispositivo pelo endereço
    public func connectToDevice(address: String) -> Bool {
        return dataSource.connectToDevice(address: address)
    }

    // Desconectar do dispositivo atualmente conectado
    public func disconnectFromDevice() -> Bool {
        return dataSource.disconnectFromDevice()
    }

    // Imprimir dados com tamanho, alinhamento e opção de negrito
    public func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        return dataSource.printData(data: data, size: size, align: align, bold: bold)
    }

    // Imprimir linha em branco um número específico de vezes
    public func printEmptyLine(callTimes: Int) -> Bool {
        return dataSource.printEmptyLine(callTimes: callTimes)
    }
}
