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
        case "getPairedDevices":
            AppModule.scanDevicesUseCase.execute { devices in
                DispatchQueue.main.async {
                    let deviceList = devices.map { "\($0.name) (\($0.address))" }
                    result(deviceList)
                }
            }

        case "connectToDevice":
            if let address = call.arguments as? [String: Any], let deviceAddress = address["address"] as? String {
                DispatchQueue.global().async {
                    let success = AppModule.connectDeviceUseCase.execute(address: deviceAddress)
                    DispatchQueue.main.async {
                        result(success)
                    }
                }
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "printData":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String,
               let fontSize = args["fontSize"] as? Int,
               let textAlign = args["textAlign"] as? Int,
               let bold = args["bold"] as? Bool {
                DispatchQueue.global().async {
                    let success = AppModule.printUseCase.execute(data: data, size: fontSize, align: textAlign, bold: bold)
                    DispatchQueue.main.async {
                        result(success)
                    }
                }
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "printEmptyLine":
            if let args = call.arguments as? [String: Any], let callTimes = args["callTimes"] as? Int {
                DispatchQueue.global().async {
                    let success = AppModule.feedLineUseCase.execute(callTimes: callTimes)
                    DispatchQueue.main.async {
                        result(success)
                    }
                }
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "disconnectFromDevice":
            DispatchQueue.global().async {
                let success = AppModule.disconnectDeviceUseCase.execute()
                DispatchQueue.main.async {
                    result(success)
                }
            }

        case "isConnected":
            let connected = AppModule.isConnectedUseCase.execute()
            result(connected)

        case "printImage":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? FlutterStandardTypedData,
               let textAlign = args["textAlign"] as? Int {
                DispatchQueue.global().async {
                    let success = AppModule.printImageUseCase.execute(data: data.data, align: textAlign)
                    DispatchQueue.main.async {
                        result(success)
                    }
                }
            } else {
                result(FlutterError(code: "400", message: "Invalid arguments", details: nil))
            }

        case "requestBluetoothPermissions":
            result("Permissions are handled via Info.plist on iOS")

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
