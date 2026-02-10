import UIKit

public class Utils {

    public static func scaleImage(_ image: UIImage, toWidth targetWidth: Int) -> UIImage? {
        let aspectRatio = image.size.height / image.size.width
        let targetHeight = CGFloat(targetWidth) * aspectRatio
        let size = CGSize(width: CGFloat(targetWidth), height: targetHeight)

        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    public static func decodeBitmap(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let bmpWidth = cgImage.width
        let bmpHeight = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bmpWidth * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: bmpHeight * bytesPerRow)

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

        var list: [String] = []

        for i in 0..<bmpHeight {
            var sb = ""
            for j in 0..<bmpWidth {
                let offset = i * bytesPerRow + j * bytesPerPixel
                let r = Int(pixelData[offset])
                let g = Int(pixelData[offset + 1])
                let b = Int(pixelData[offset + 2])

                if r > 160 && g > 160 && b > 160 {
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

        let bmpHexList = binaryListToHexStringList(list)

        // GS v 0 command header: 1D 76 30 00 xL xH yL yH
        // xL/xH = bytes per line (little-endian), yL/yH = height in lines (little-endian)
        var header = Data([
            0x1D, 0x76, 0x30, 0x00,
            UInt8(bitLen & 0xFF),
            UInt8((bitLen >> 8) & 0xFF),
            UInt8(bmpHeight & 0xFF),
            UInt8((bmpHeight >> 8) & 0xFF)
        ])

        let rasterData = hexListToData(bmpHexList)
        header.append(rasterData)

        return header
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
