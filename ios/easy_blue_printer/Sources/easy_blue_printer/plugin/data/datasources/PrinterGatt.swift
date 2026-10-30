import Foundation
import CoreBluetooth

/// O que se sabe dos perfis GATT das impressoras térmicas BLE.
///
/// Não existe um serviço padrão de impressão no BLE: cada fabricante de módulo
/// usa o seu, e a maioria das marcas compra o mesmo punhado de módulos. Esta
/// lista serve a três coisas — achar impressoras que já estão conectadas ao
/// iPhone (e por isso pararam de anunciar), pôr as impressoras no topo da busca
/// e escolher a característica certa para mandar os bytes.
enum PrinterGatt {

    /// Serviços de dados dos módulos usados em impressoras térmicas.
    static let printerServices: [CBUUID] = [
        CBUUID(string: "18F0"),                                 // módulos chineses genéricos (MTP, PT-210, Xprinter…)
        CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"), // idem, segunda família mais comum
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"), // Microchip/ISSC transparent UART
        CBUUID(string: "FF00"),
        CBUUID(string: "FFE0"),                                 // HM-10 e clones
        CBUUID(string: "FFF0"),
        CBUUID(string: "AE30"),
        CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"), // Nordic UART
        CBUUID(string: "38EB4A80-C570-11E3-9507-0002A5D5C51B"), // Zebra
    ]

    /// Característica de escrita de cada serviço acima. Quando o serviço tem
    /// mais de uma gravável, é esta que recebe os dados — as outras costumam
    /// ser de configuração.
    static let printerWriteCharacteristics: [CBUUID] = [
        CBUUID(string: "2AF1"),
        CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"),
        CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3"),
        CBUUID(string: "FF02"),
        CBUUID(string: "FFE1"),
        CBUUID(string: "FFF2"),
        CBUUID(string: "AE01"),
        CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"),
        CBUUID(string: "38EB4A82-C570-11E3-9507-0002A5D5C51B"),
    ]

    /// Serviços que quase todo periférico expõe. Só entram na procura de
    /// periféricos já conectados ao sistema, para alcançar impressoras de
    /// módulo desconhecido que alguém pareou nos Ajustes do iPhone.
    static let genericServices: [CBUUID] = [
        CBUUID(string: "180A"), // Device Information
    ]

    /// Serviços que nunca levam dados de impressão. Escrever ESC/POS neles vai
    /// de nada acontecer a renomear o aparelho ou disparar uma atualização de
    /// firmware, então ficam fora mesmo quando são os únicos graváveis.
    static let ignoredServices: Set<CBUUID> = [
        CBUUID(string: "1800"),                                 // GAP — o nome do aparelho pode ser gravável
        CBUUID(string: "1801"),                                 // GATT
        CBUUID(string: "1802"),                                 // Immediate Alert
        CBUUID(string: "1803"),                                 // Link Loss
        CBUUID(string: "180A"),                                 // Device Information
        CBUUID(string: "180F"),                                 // Battery
        CBUUID(string: "FE59"),                                 // Nordic Secure DFU
        CBUUID(string: "00001530-1212-EFDE-1523-785FEABCD123"), // Nordic Legacy DFU
        CBUUID(string: "00010203-0405-0607-0809-0A0B0C0D1912"), // Telink OTA
        CBUUID(string: "8D53DC1D-1DB7-4CD3-868B-8A527460AA84"), // MCUmgr SMP
        CBUUID(string: "F000FFC0-0451-4000-B000-000000000000"), // TI OAD
        CBUUID(string: "1D14D6EE-FD63-4FA1-BFA4-8F47B42119F0"), // Silicon Labs OTA
    ]

    /// Trechos de nome que indicam impressora. Só ordenam a lista — um falso
    /// positivo sobe um aparelho, não esconde nenhum.
    private static let printerNameHints = [
        "print", "pos", "mtp", "mpt", "rpp", "pt-", "xp-", "zj", "dpp", "spp-r", "thermal",
        "leopardo", "goojprt", "bixolon", "datecs", "zebra", "sunmi", "epson", "star",
    ]

    static func nameLooksLikePrinter(_ name: String?) -> Bool {
        guard let name = name?.lowercased() else { return false }
        return printerNameHints.contains { name.contains($0) }
    }

    /// A característica que recebe os bytes de impressão, escolhida entre
    /// todos os serviços — e não a primeira gravável do primeiro serviço que
    /// responder, que podia ser a de configuração ou a de firmware.
    ///
    /// Preferência: característica conhecida de impressora, depois qualquer
    /// gravável de serviço conhecido, depois qualquer gravável de serviço
    /// desconhecido. No empate, a que aceita escrita sem resposta, que é como
    /// os canais de dados tipo UART costumam ser.
    static func bestWritableCharacteristic(in services: [CBService]) -> CBCharacteristic? {
        var best: (score: Int, characteristic: CBCharacteristic)?

        for service in services where !ignoredServices.contains(service.uuid) {
            for characteristic in service.characteristics ?? [] {
                let properties = characteristic.properties
                guard properties.contains(.write) || properties.contains(.writeWithoutResponse) else { continue }

                let tier: Int
                if printerWriteCharacteristics.contains(characteristic.uuid) {
                    tier = 3
                } else if printerServices.contains(service.uuid) {
                    tier = 2
                } else {
                    tier = 1
                }
                let score = tier * 2 + (properties.contains(.writeWithoutResponse) ? 1 : 0)

                if best == nil || score > best!.score {
                    best = (score, characteristic)
                }
            }
        }

        return best?.characteristic
    }
}
