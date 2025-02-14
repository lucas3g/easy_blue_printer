package com.maktubcompany.easy_blue_printer

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.maktubcompany.easy_blue_printer.plugin.di.AppModule

/** EasyBluePrinterPlugin */
class EasyBluePrinterPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_blue_printer")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "scanDevices" -> result.success(AppModule.scanDevicesUseCase.execute().map { "${it.name} (${it.address})" })
      "connectToDevice" -> {
        val address = call.argument<String>("address")
        result.success(address?.let { AppModule.connectDeviceUseCase.execute(it) })
      }
      "printData" -> {
        val data = call.argument<String>("data")
        val fontSize = call.argument<Int>("fontSize")
        val align = call.argument<Int>("textAlign")
        val bold = call.argument<Boolean>("bold")

        if (data != null && fontSize != null && align != null && bold != null) {
          result.success(AppModule.printUseCase.execute(data, fontSize, align, bold))
        } else {
          result.error("400", "Invalid arguments", null)
        }
      }
      "printEmptyLine" -> {
        val callTimes = call.argument<Int>("callTimes")

        if (callTimes != null) {
          result.success(AppModule.feedLineUseCase.execute(callTimes))
        } else {
          result.error("400", "Invalid arguments", null)
        }
      }
      "disconnectFromDevice" -> result.success(AppModule.disconnectDeviceUseCase.execute())
      "isConnected" -> result.success(AppModule.isConnectedUseCase.execute())
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}