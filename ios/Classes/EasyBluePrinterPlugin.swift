import Flutter
import UIKit

public class EasyBluePrinterPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "easy_blue_printer", binaryMessenger: registrar.messenger())
        let instance = EasyBluePrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanDevices":
            // Execute scanDevicesUseCase and return the list of devices
            let devices = AppModule.scanDevicesUseCase.execute()
            let deviceList = devices.map { "\($0.name) (\($0.address))" }
            result(deviceList)

        case "connectToDevice":
            // Retrieve address and connect to the device
            if let address = call.arguments as? [String: Any], let deviceAddress = address["address"] as? String {
                let success = AppModule.connectDeviceUseCase.execute(address: deviceAddress)
                result(success)
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "printData":
            // Print data with arguments: data, fontSize, textAlign, bold
            if let args = call.arguments as? [String: Any] {
                if let data = args["data"] as? String,
                let fontSize = args["fontSize"] as? Int,
                let textAlign = args["textAlign"] as? Int,
                let bold = args["bold"] as? Bool {
                    let success = AppModule.printUseCase.execute(data: data, size: fontSize, align: textAlign, bold: bold)
                    result(success)
                } else {
                    result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
                }
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "printEmptyLine":
            // Feed empty lines with callTimes argument
            if let args = call.arguments as? [String: Any], let callTimes = args["callTimes"] as? Int {
                let success = AppModule.feedLineUseCase.execute(callTimes: callTimes)
                result(success)
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "disconnectFromDevice":
            // Disconnect from device
            let success = AppModule.disconnectDeviceUseCase.execute()
            result(success)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
