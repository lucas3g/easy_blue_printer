import Foundation
import CoreBluetooth
import UIKit

/// O motivo de uma busca não poder nem começar. Só a falta de permissão vira
/// erro: com o Bluetooth desligado a busca devolve lista vazia, como no
/// Android, e o próprio iOS já pede ao usuário para ligar.
public enum BluetoothScanError: Error {
    case unauthorized
}

public class BluetoothDataSource: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    /// Um aparelho visto na busca. Guarda o periférico porque o CoreBluetooth
    /// só conecta em quem a app ainda segura uma referência.
    private struct Candidate {
        let peripheral: CBPeripheral
        var name: String
        var nameQuality: Int
        var rssi: Int
        var looksLikePrinter: Bool
        let order: Int
    }

    /// De onde veio o nome: o anunciado é o mais fresco; o do GAP é o que o
    /// iOS guardou de uma conexão anterior; o genérico é para quem anuncia
    /// serviço de impressora sem nome nenhum.
    private enum NameQuality {
        static let fallback = 0
        static let gap = 1
        static let advertised = 2
    }

    private static let scanDuration: TimeInterval = 5
    private static let connectTimeout: TimeInterval = 10
    private static let stateTimeout: TimeInterval = 10

    // Tudo daqui até o fim do bloco só é lido e escrito na `bluetoothQueue`,
    // que é também a fila dos delegates do CoreBluetooth.
    private let bluetoothQueue = DispatchQueue(label: "com.easy_blue_printer.bluetooth")
    private var bluetoothManager: CBCentralManager!
    private var stateWaiters: [(CBManagerState) -> Void] = []
    private var scanWaiters: [(Result<[BluetoothDeviceEntity], BluetoothScanError>) -> Void] = []
    private var isScanning = false
    private var candidates: [UUID: Candidate] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var connectingPeripheral: CBPeripheral?
    private var writableCharacteristic: CBCharacteristic?
    private var connectionSemaphore: DispatchSemaphore?
    private var pendingServiceCount: Int = 0

    /// Uma conexão por vez: a reconexão automática da abertura e o toque do
    /// usuário podem chegar juntos, e dois `connect` dividindo o mesmo
    /// semáforo deixavam um deles esperando o timeout inteiro.
    private let connectLock = DispatchSemaphore(value: 1)

    private var paperWidth: Int = 384

    /// O aquecimento pedido pelo chamador, guardado porque o `ESC @` no fim de
    /// cada imagem o apaga e ele precisa ser reposto. `nil` mantém o de
    /// fábrica e não manda comando nenhum.
    private var heatingTime: Int?

    // Semaphore used to block writeChunk until CoreBluetooth confirms the write.
    // Set on the print queue and signalled from the Bluetooth queue, hence the lock.
    private let writeLock = NSLock()
    private var _pendingWriteSemaphore: DispatchSemaphore?
    private var pendingWriteSemaphore: DispatchSemaphore? {
        get {
            writeLock.lock()
            defer { writeLock.unlock() }
            return _pendingWriteSemaphore
        }
        set {
            writeLock.lock()
            _pendingWriteSemaphore = newValue
            writeLock.unlock()
        }
    }

    // Accumulates ESC/POS bytes from printData/printEmptyLine calls.
    // All buffered data is sent as one continuous stream when commitPrint,
    // printEmptyLine, or printImage is called.
    private var printBuffer = Data()

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
    }

    // MARK: - Public methods

    /// Busca por alguns segundos e devolve tudo que dá para conectar, com as
    /// impressoras no topo e as mais próximas primeiro.
    ///
    /// Antes desta versão uma impressora ficava de fora quando: o nome só vinha
    /// no anúncio (e não em `peripheral.name`); ela já estava conectada ao
    /// iPhone — pareada nos Ajustes ou aberta por outra app — e por isso tinha
    /// parado de anunciar; ou o Bluetooth ainda não estava pronto e a busca
    /// nunca respondia.
    public func scanDevices(completion: @escaping (Result<[BluetoothDeviceEntity], BluetoothScanError>) -> Void) {
        bluetoothQueue.async { [weak self] in
            guard let self = self else {
                completion(.success([]))
                return
            }

            self.whenStateKnown { state in
                switch state {
                case .poweredOn:
                    // Quem chega com uma busca em andamento pega carona nela:
                    // recomeçar zerava a lista e deixava a primeira chamada
                    // esperando para sempre.
                    self.scanWaiters.append(completion)
                    self.startScanIfIdle()
                case .unauthorized:
                    completion(.failure(.unauthorized))
                default:
                    completion(.success([]))
                }
            }
        }
    }

    /// Conecta pelo identificador que a busca devolveu, mesmo sem uma busca
    /// nesta sessão: o iOS devolve o periférico de quem ele já conhece, e é
    /// isso que deixa a reconexão automática da abertura do app funcionar.
    public func connectToDevice(address: String) -> Bool {
        guard let identifier = UUID(uuidString: address) else { return false }

        connectLock.wait()
        defer { connectLock.signal() }

        guard waitForState() == .poweredOn else { return false }

        enum Start {
            case unknownDevice
            case alreadyConnected
            case connecting(CBPeripheral, DispatchSemaphore)
        }

        let start: Start = bluetoothQueue.sync {
            if let current = self.connectedPeripheral,
               current.identifier == identifier,
               current.state == .connected,
               self.writableCharacteristic != nil {
                return .alreadyConnected
            }

            guard let peripheral = self.knownPeripheral(identifier) else { return .unknownDevice }

            self.bluetoothManager.stopScan()
            if let current = self.connectedPeripheral, current.identifier != identifier {
                self.bluetoothManager.cancelPeripheralConnection(current)
            }
            self.connectedPeripheral = nil
            self.writableCharacteristic = nil

            let semaphore = DispatchSemaphore(value: 0)
            self.connectingPeripheral = peripheral
            self.connectionSemaphore = semaphore

            if peripheral.state == .connected {
                self.discoverServices(of: peripheral)
            } else {
                self.bluetoothManager.connect(peripheral, options: nil)
            }
            return .connecting(peripheral, semaphore)
        }

        switch start {
        case .unknownDevice:
            return false
        case .alreadyConnected:
            return true
        case .connecting(let peripheral, let semaphore):
            let finished = semaphore.wait(timeout: .now() + Self.connectTimeout) == .success

            return bluetoothQueue.sync {
                self.connectingPeripheral = nil
                self.connectionSemaphore = nil

                let ready = finished
                    && self.connectedPeripheral?.identifier == identifier
                    && peripheral.state == .connected
                    && self.writableCharacteristic != nil
                if !ready {
                    // O `connect` do CoreBluetooth não expira sozinho. Sem
                    // cancelar, a impressora fora de alcance conectava minutos
                    // depois, com o app achando que estava desconectado.
                    self.bluetoothManager.cancelPeripheralConnection(peripheral)
                    if self.connectedPeripheral?.identifier == identifier {
                        self.connectedPeripheral = nil
                        self.writableCharacteristic = nil
                    }
                }
                return ready
            }
        }
    }

    public func disconnectFromDevice() -> Bool {
        bluetoothQueue.sync {
            for peripheral in [self.connectedPeripheral, self.connectingPeripheral].compactMap({ $0 }) {
                self.bluetoothManager.cancelPeripheralConnection(peripheral)
            }
            self.connectedPeripheral = nil
            self.writableCharacteristic = nil
            self.connectionSemaphore?.signal()
        }
        pendingWriteSemaphore?.signal()
        return true
    }

    // Builds ESC/POS bytes and appends to printBuffer — no network IO.
    // Data is only sent when commitPrint(), printEmptyLine(), or printImage() is called.
    public func printData(data: String, size: Int, align: Int, bold: Bool) -> Bool {
        var bytes = Data()
        bytes.append(contentsOf: getAlignmentData(for: align))
        bytes.append(contentsOf: bold ? [0x1B, 0x47, 0x01] : [0x1B, 0x47, 0x00])
        bytes.append(contentsOf: getFontSizeData(for: size))
        bytes.append(data.data(using: .utf8) ?? Data())
        bytes.append(contentsOf: [0x0A])
        printBuffer.append(bytes)
        return true
    }

    // Appends newlines to buffer. The buffer is flushed by commitPrint()
    // when the Dart queue empties, or by printImage() before image data.
    public func printEmptyLine(callTimes: Int) -> Bool {
        let newlines = Data(repeating: 0x0A, count: callTimes)
        printBuffer.append(newlines)
        return true
    }

    // Sends all buffered bytes to the printer. Called by the Dart queue
    // when all enqueued jobs are done (handles text-only receipts).
    public func commitPrint() -> Bool {
        return flushPrintBuffer()
    }

    // Sends buffered bytes as one continuous stream — same chunking used for images.
    private func flushPrintBuffer() -> Bool {
        if printBuffer.isEmpty { return true }
        let bytes = printBuffer
        printBuffer = Data()
        return writeImageData(bytes)
    }

    public func isConnected() -> Bool {
        return bluetoothQueue.sync {
            self.connectedPeripheral?.state == .connected && self.writableCharacteristic != nil
        }
    }

    public func configurePrinter(paperWidth: Int, heatingTime: Int?) {
        self.paperWidth = paperWidth
        self.heatingTime = heatingTime
        writeHeating()
    }

    /// `ESC 7 n1 n2 n3`: pontos simultâneos, tempo de aquecimento e intervalo.
    /// Só o tempo muda — é ele que escurece o traço. Vai para o buffer como
    /// qualquer outro comando, então só chega à impressora no próximo envio.
    private func writeHeating() {
        guard let heatingTime else { return }
        printBuffer.append(contentsOf: [0x1B, 0x37, 0x07, UInt8(heatingTime & 0xFF), 0x02])
    }

    // Encodes the image to ESC/POS bytes and appends them to printBuffer.
    // No socket IO happens here — everything is sent as one continuous stream
    // by commitPrint(), together with any preceding and following text.
    public func printImage(data: Data, align: Int) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        guard let scaledImage = Utils.scaleImage(image, toWidth: paperWidth) else { return false }
        guard let command = Utils.decodeBitmap(scaledImage) else { return false }

        printBuffer.append(contentsOf: getAlignmentData(for: align))
        printBuffer.append(command)
        // Paper feed for tear-off
        printBuffer.append(contentsOf: [0x0A, 0x0A, 0x0A, 0x0A])
        // Reset printer to text mode so subsequent text commands work correctly
        printBuffer.append(contentsOf: [0x1B, 0x40])
        // O `ESC @` inicializa a impressora, e isso zera também o aquecimento
        // do `ESC 7`. Sem repor aqui, um documento fatiado imprime a primeira
        // fatia na densidade pedida e todas as outras na de fábrica — o papel
        // sai mais fraco da emenda para baixo.
        writeHeating()
        return true
    }

    // MARK: - Discovery helpers (bluetoothQueue only)

    /// Roda `body` assim que o estado do Bluetooth deixa de ser provisório.
    /// Logo depois de criado, o gerenciador fica em `.unknown` — e continua
    /// assim enquanto o diálogo de permissão está na tela.
    private func whenStateKnown(_ body: @escaping (CBManagerState) -> Void) {
        let state = bluetoothManager.state
        if state == .unknown || state == .resetting {
            stateWaiters.append(body)
        } else {
            body(state)
        }
    }

    /// O mesmo, de forma bloqueante, para quem está fora da `bluetoothQueue`.
    private func waitForState() -> CBManagerState {
        let semaphore = DispatchSemaphore(value: 0)
        var resolved = CBManagerState.unknown
        bluetoothQueue.async {
            self.whenStateKnown { state in
                resolved = state
                semaphore.signal()
            }
        }
        guard semaphore.wait(timeout: .now() + Self.stateTimeout) == .success else { return .unknown }
        return resolved
    }

    private func startScanIfIdle() {
        guard !isScanning else { return }
        isScanning = true
        candidates.removeAll()

        addSystemConnectedPeripherals()

        // Com duplicatas: o primeiro pacote de muitas impressoras chega sem o
        // nome, que só vem na resposta ao scan. Sem repetição, o aparelho era
        // descartado por não ter nome e nunca mais aparecia.
        bluetoothManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        bluetoothQueue.asyncAfter(deadline: .now() + Self.scanDuration) { [weak self] in
            self?.finishScan()
        }
    }

    private func finishScan() {
        if bluetoothManager.state == .poweredOn {
            bluetoothManager.stopScan()
        }
        isScanning = false

        if let connected = connectedPeripheral {
            addKnownPeripheral(connected, looksLikePrinter: true)
        }

        let devices = candidates.values
            .sorted { a, b in
                if a.looksLikePrinter != b.looksLikePrinter { return a.looksLikePrinter }
                if a.rssi != b.rssi { return a.rssi > b.rssi }
                return a.order < b.order
            }
            .map { BluetoothDeviceEntity(name: $0.name, address: $0.peripheral.identifier.uuidString) }

        let waiters = scanWaiters
        scanWaiters.removeAll()
        waiters.forEach { $0(.success(devices)) }
    }

    /// Impressoras já conectadas ao iPhone não anunciam — é o caso de quem
    /// pareou nos Ajustes, como faria no Android, ou deixou aberta a app do
    /// fabricante. O iOS só as entrega pedindo por serviço.
    private func addSystemConnectedPeripherals() {
        for peripheral in bluetoothManager.retrieveConnectedPeripherals(withServices: PrinterGatt.printerServices) {
            addKnownPeripheral(peripheral, looksLikePrinter: true)
        }
        for peripheral in bluetoothManager.retrieveConnectedPeripherals(withServices: PrinterGatt.genericServices) {
            addKnownPeripheral(peripheral, looksLikePrinter: PrinterGatt.nameLooksLikePrinter(peripheral.name))
        }
    }

    /// Entrada para um periférico que não veio de anúncio — sem RSSI, então
    /// vai para o topo do seu grupo: está conectado, logo está perto.
    private func addKnownPeripheral(_ peripheral: CBPeripheral, looksLikePrinter: Bool) {
        guard candidates[peripheral.identifier] == nil else { return }
        let name = Self.usableName(peripheral.name)
        candidates[peripheral.identifier] = Candidate(
            peripheral: peripheral,
            name: name ?? Self.fallbackName(for: peripheral),
            nameQuality: name == nil ? NameQuality.fallback : NameQuality.gap,
            rssi: 0,
            looksLikePrinter: looksLikePrinter,
            order: candidates.count
        )
    }

    private func knownPeripheral(_ identifier: UUID) -> CBPeripheral? {
        if let candidate = candidates[identifier] { return candidate.peripheral }
        if let connected = connectedPeripheral, connected.identifier == identifier { return connected }
        if let known = bluetoothManager.retrievePeripherals(withIdentifiers: [identifier]).first { return known }
        return bluetoothManager
            .retrieveConnectedPeripherals(withServices: PrinterGatt.printerServices + PrinterGatt.genericServices)
            .first { $0.identifier == identifier }
    }

    private static func usableName(_ raw: String?) -> String? {
        guard let name = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty,
              name.caseInsensitiveCompare("Unknown") != .orderedSame else { return nil }
        return name
    }

    private static func fallbackName(for peripheral: CBPeripheral) -> String {
        return "Printer \(peripheral.identifier.uuidString.prefix(4))"
    }

    // MARK: - Connection helpers (bluetoothQueue only)

    private func discoverServices(of peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        writableCharacteristic = nil
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    // MARK: - Write helpers

    /// Quantas linhas de raster a impressora queima por segundo — ~50 mm/s a
    /// 203 dpi. Não muda com a bobina; o que muda é o tamanho da linha.
    private static let linesPerSecond: Double = 400

    /// Quantos bytes de raster a impressora consome por segundo, pela bobina
    /// configurada: 8 pontos por byte, 72 bytes por linha na de 80mm e 48 na
    /// de 58mm.
    private func bytesPerSecond() -> Double {
        return Double(max(paperWidth / 8, 1)) * Self.linesPerSecond
    }

    private func writeImageData(_ data: Data) -> Bool {
        let target: (CBPeripheral, CBCharacteristic)? = bluetoothQueue.sync {
            guard let peripheral = self.connectedPeripheral,
                  let characteristic = self.writableCharacteristic else { return nil }
            return (peripheral, characteristic)
        }
        guard let target = target else { return false }
        let (peripheral, characteristic) = target

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        let mtu = peripheral.maximumWriteValueLength(for: writeType)
        // Limita a 128 bytes para compatibilidade com impressoras de buffer pequeno.
        let chunkSize = min(max(mtu, 20), 128)
        let bytesPerSecond = self.bytesPerSecond()
        var offset = 0

        while offset < data.count {
            // A escrita sem resposta não falha nunca do lado de cá: se a
            // impressora caiu no meio, o envio seguia "com sucesso" para o
            // nada e o app anunciava o cupom como impresso.
            guard peripheral.state == .connected else { return false }

            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)
            let started = Date()

            var attempt = 0
            while true {
                let ok = writeChunk(chunk, to: peripheral, characteristic: characteristic, type: writeType)
                if ok { break }
                attempt += 1
                if attempt > 2 { return false }
            }

            // Piso de tempo, e não espera fixa: com `.withoutResponse` o
            // CoreBluetooth aceita os chunks muito mais rápido do que o papel
            // sai, e quem chamou receberia o fim do envio com metade do
            // documento ainda por imprimir. Onde o handshake já é mais lento
            // que o papel — o caso de `.withResponse` — isto não espera nada.
            let devido = Double(chunk.count) / bytesPerSecond
            let decorrido = Date().timeIntervalSince(started)
            if decorrido < devido {
                Thread.sleep(forTimeInterval: devido - decorrido)
            }

            offset = end
        }
        return true
    }

    /// Envia um único chunk e bloqueia até confirmação do peripheral (sem delay fixo).
    ///
    /// - `.withResponse`: aguarda `didWriteValueFor` via semáforo (timeout 5s).
    /// - `.withoutResponse`: verifica `canSendWriteWithoutResponse`; se falso, aguarda
    ///   `peripheralIsReady(toSendWriteWithoutResponse:)` antes de escrever.
    private func writeChunk(
        _ chunk: Data,
        to peripheral: CBPeripheral,
        characteristic: CBCharacteristic,
        type writeType: CBCharacteristicWriteType
    ) -> Bool {
        if writeType == .withResponse {
            let semaphore = DispatchSemaphore(value: 0)
            pendingWriteSemaphore = semaphore
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            let result = semaphore.wait(timeout: .now() + 5.0)
            pendingWriteSemaphore = nil
            return result == .success && peripheral.state == .connected
        } else {
            if !peripheral.canSendWriteWithoutResponse {
                let semaphore = DispatchSemaphore(value: 0)
                pendingWriteSemaphore = semaphore
                // Confere de novo já com o semáforo publicado: o aviso de
                // "pronto" pode ter chegado entre a primeira checagem e aqui.
                if !peripheral.canSendWriteWithoutResponse {
                    _ = semaphore.wait(timeout: .now() + 5.0)
                }
                pendingWriteSemaphore = nil
            }
            guard peripheral.state == .connected else { return false }
            peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            return true
        }
    }

    private func getAlignmentData(for align: Int) -> [UInt8] {
        switch align {
        case 0: return [0x1B, 0x61, 0x00]
        case 1: return [0x1B, 0x61, 0x01]
        case 2: return [0x1B, 0x61, 0x02]
        default: return []
        }
    }

    private func getFontSizeData(for size: Int) -> [UInt8] {
        switch size {
        case 0: return [0x1B, 0x21, 0x03]
        case 1: return [0x1B, 0x21, 0x08]
        case 2: return [0x1B, 0x21, 0x10]
        case 3: return [0x1B, 0x21, 0x30]
        default: return []
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        if state == .unknown || state == .resetting { return }

        // Antes só `.poweredOn` destravava quem esperava: com a permissão
        // negada ou o Bluetooth desligado na abertura, a busca nunca respondia
        // e a tela ficava carregando para sempre.
        let waiters = stateWaiters
        stateWaiters.removeAll()
        waiters.forEach { $0(state) }

        if state != .poweredOn {
            // Desligado, o iOS invalida todos os periféricos sem avisar um a um.
            connectedPeripheral = nil
            writableCharacteristic = nil
            connectionSemaphore?.signal()
            pendingWriteSemaphore?.signal()
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard isScanning else { return }
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber, !connectable.boolValue {
            return
        }

        let advertisedServices = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            + (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? [])
        let advertisesPrinterService = advertisedServices.contains { PrinterGatt.printerServices.contains($0) }

        // O nome anunciado vem primeiro: `peripheral.name` é o nome GAP que o
        // iOS guardou, e costuma ser `nil` em aparelho nunca conectado.
        let advertisedName = Self.usableName(advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let gapName = Self.usableName(peripheral.name)
        let name = advertisedName ?? gapName
        let quality = advertisedName != nil
            ? NameQuality.advertised
            : (gapName != nil ? NameQuality.gap : NameQuality.fallback)

        // 127 é o "RSSI indisponível" do CoreBluetooth.
        let rssi = RSSI.intValue == 127 ? -127 : RSSI.intValue

        if var candidate = candidates[peripheral.identifier] {
            if let name = name, quality >= candidate.nameQuality {
                candidate.name = name
                candidate.nameQuality = quality
            }
            candidate.rssi = max(candidate.rssi, rssi)
            candidate.looksLikePrinter = candidate.looksLikePrinter
                || advertisesPrinterService
                || PrinterGatt.nameLooksLikePrinter(name)
            candidates[peripheral.identifier] = candidate
            return
        }

        // Sem nome e sem serviço de impressora é beacon, fone, relógio…
        // nada que valha uma linha na lista.
        guard name != nil || advertisesPrinterService else { return }

        candidates[peripheral.identifier] = Candidate(
            peripheral: peripheral,
            name: name ?? Self.fallbackName(for: peripheral),
            nameQuality: quality,
            rssi: rssi,
            looksLikePrinter: advertisesPrinterService || PrinterGatt.nameLooksLikePrinter(name),
            order: candidates.count
        )
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard peripheral.identifier == connectingPeripheral?.identifier else {
            // Conexão que ninguém está esperando — sobra de uma tentativa que
            // já expirou. Ficar com ela seria uma impressora presa à app sem
            // que o app saiba.
            central.cancelPeripheralConnection(peripheral)
            return
        }
        discoverServices(of: peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if peripheral.identifier == connectingPeripheral?.identifier {
            connectionSemaphore?.signal()
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral.identifier == connectedPeripheral?.identifier {
            connectedPeripheral = nil
            writableCharacteristic = nil
            pendingWriteSemaphore?.signal()
        }
        if peripheral.identifier == connectingPeripheral?.identifier {
            connectionSemaphore?.signal()
        }
    }

    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral.identifier == connectingPeripheral?.identifier else { return }

        guard error == nil, let services = peripheral.services, !services.isEmpty else {
            connectionSemaphore?.signal()
            return
        }

        pendingServiceCount = services.count
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // Called when a .withResponse write completes — unblocks writeChunk.
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        pendingWriteSemaphore?.signal()
    }

    // Called when the peripheral is ready to accept another .withoutResponse write — unblocks writeChunk.
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        pendingWriteSemaphore?.signal()
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard peripheral.identifier == connectingPeripheral?.identifier else { return }

        pendingServiceCount -= 1
        guard pendingServiceCount <= 0 else { return }

        // Escolhe só com todos os serviços na mão: decidir no primeiro que
        // respondesse pegava a característica gravável de configuração ou de
        // firmware e a impressora conectava sem imprimir nada.
        writableCharacteristic = PrinterGatt.bestWritableCharacteristic(in: peripheral.services ?? [])
        connectionSemaphore?.signal()
    }
}
