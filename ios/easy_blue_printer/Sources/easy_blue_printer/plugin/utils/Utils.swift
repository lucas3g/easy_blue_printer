import UIKit

public class Utils {

    public static func scaleImage(_ image: UIImage, toWidth targetWidth: Int) -> UIImage? {
        let aspectRatio = image.size.height / image.size.width
        let targetHeight = CGFloat(targetWidth) * aspectRatio
        let size = CGSize(width: CGFloat(targetWidth), height: targetHeight)

        // Contexto **não** opaco: um opaco achata a imagem sobre um fundo
        // indefinido (na prática preto) antes de `decodeBitmap` ver o alfa, e
        // aí o tratamento de transparência de lá nunca entra — um PNG com
        // fundo transparente saía queimado de ponta a ponta.
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    /// Altura de cada bloco `GS v 0`.
    ///
    /// Um raster inteiro num comando só significa alimentar a impressora por
    /// dezenas de segundos sem que ela possa imprimir nada: muitos modelos
    /// desistem no meio e voltam ao modo texto, e o resto dos bytes sai como
    /// caracteres no papel. Em blocos, cada comando é pequeno, a impressora
    /// imprime e pede o próximo. Sem avanço de papel entre eles, o resultado
    /// é contínuo.
    private static let bandHeight = 64

    public static func decodeBitmap(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let bmpWidth = cgImage.width
        let bmpHeight = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bmpWidth * bytesPerPixel
        // Branco, e não zero: o buffer zerado é preto opaco, então tudo que a
        // imagem deixasse transparente sairia queimado no papel.
        var pixelData = [UInt8](repeating: 0xFF, count: bmpHeight * bytesPerRow)

        guard let context = CGContext(
            data: &pixelData,
            width: bmpWidth,
            height: bmpHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: bmpWidth, height: bmpHeight))

        var bitLen = bmpWidth / 8
        let zeroCount = bmpWidth % 8
        var zeroStr = ""
        if zeroCount > 0 {
            bitLen = bmpWidth / 8 + 1
            for _ in 0..<(8 - zeroCount) {
                zeroStr += "0"
            }
        }

        var out = Data()
        var top = 0

        while top < bmpHeight {
            let band = min(bandHeight, bmpHeight - top)
            var list: [String] = []

            for i in top..<(top + band) {
                var sb = ""
                for j in 0..<bmpWidth {
                    let offset = i * bytesPerRow + j * bytesPerPixel
                    let r = Int(pixelData[offset])
                    let g = Int(pixelData[offset + 1])
                    let b = Int(pixelData[offset + 2])
                    let a = Int(pixelData[offset + 3])

                    // Transparente é vazio, e vazio não queima.
                    if a < 128 || (r > 160 && g > 160 && b > 160) {
                        sb += "0"
                    } else {
                        sb += "1"
                    }
                }
                if zeroCount > 0 {
                    sb += zeroStr
                }
                list.append(sb)
            }

            // GS v 0 command header: 1D 76 30 00 xL xH yL yH
            // xL/xH = bytes per line (little-endian), yL/yH = height in lines
            out.append(Data([
                0x1D, 0x76, 0x30, 0x00,
                UInt8(bitLen & 0xFF),
                UInt8((bitLen >> 8) & 0xFF),
                UInt8(band & 0xFF),
                UInt8((band >> 8) & 0xFF)
            ]))
            out.append(hexListToData(binaryListToHexStringList(list)))

            top += band
        }

        return out
    }

    // MARK: - Private helpers

    private static let hexChars = "0123456789ABCDEF"
    private static let binaryArray = [
        "0000", "0001", "0010", "0011",
        "0100", "0101", "0110", "0111",
        "1000", "1001", "1010", "1011",
        "1100", "1101", "1110", "1111"
    ]

    private static func binaryListToHexStringList(_ list: [String]) -> [String] {
        var hexList: [String] = []
        for binaryStr in list {
            var sb = ""
            var i = 0
            while i < binaryStr.count {
                let start = binaryStr.index(binaryStr.startIndex, offsetBy: i)
                let end = binaryStr.index(start, offsetBy: 8)
                let str = String(binaryStr[start..<end])
                sb += binaryStrToHexString(str)
                i += 8
            }
            hexList.append(sb)
        }
        return hexList
    }

    private static func binaryStrToHexString(_ binaryStr: String) -> String {
        let f4 = String(binaryStr.prefix(4))
        let b4 = String(binaryStr.suffix(4))
        let hexCharsArray = Array(hexChars)
        var hex = ""
        for (i, bin) in binaryArray.enumerated() {
            if f4 == bin {
                hex += String(hexCharsArray[i])
            }
        }
        for (i, bin) in binaryArray.enumerated() {
            if b4 == bin {
                hex += String(hexCharsArray[i])
            }
        }
        return hex
    }

    private static func hexListToData(_ list: [String]) -> Data {
        var result = Data()
        for hexStr in list {
            if let bytes = hexStringToBytes(hexStr) {
                result.append(bytes)
            }
        }
        return result
    }

    private static func hexStringToBytes(_ hexString: String) -> Data? {
        let hex = hexString.uppercased()
        let length = hex.count / 2
        var data = Data(capacity: length)
        let chars = Array(hex)
        for i in 0..<length {
            let pos = i * 2
            let high = charToNibble(chars[pos])
            let low = charToNibble(chars[pos + 1])
            data.append(UInt8((high << 4) | low))
        }
        return data
    }

    private static func charToNibble(_ c: Character) -> Int {
        return hexChars.firstIndex(of: c).map {
            hexChars.distance(from: hexChars.startIndex, to: $0)
        } ?? 0
    }
}
