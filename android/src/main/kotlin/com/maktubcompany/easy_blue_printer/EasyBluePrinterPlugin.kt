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

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_blue_printer")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPairedDevices" -> {
        Thread {
          try {
            val devices = AppModule.getPairedDevices.execute().map { "${it.name} (${it.address})" }
            result.success(devices)
          } catch (e: Exception) {
            result.error("SCAN_ERROR", e.message, null)
          }
        }.start()
      }
      "connectToDevice" -> {
        val address = call.argument<String>("address")
        if (address == null) {
          result.error("400", "Address is required", null)
          return
        }

        Thread {
          try {
            val connected = AppModule.connectDeviceUseCase.execute(address)
            result.success(connected)
          } catch (e: Exception) {
            result.error("CONNECTION_ERROR", e.message, null)
          }
        }.start()
      }
      "printData" -> {
        val data = call.argument<String>("data")
        val fontSize = call.argument<Int>("fontSize")
        val align = call.argument<Int>("textAlign")
        val bold = call.argument<Boolean>("bold")

        if (data == null || fontSize == null || align == null || bold == null) {
          result.error("400", "Invalid arguments", null)
          return
        }

        Thread {
          try {
            val printed = AppModule.printUseCase.execute(data, fontSize, align, bold)
            result.success(printed)
          } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
          }
        }.start()
      }
      "printEmptyLine" -> {
        val callTimes = call.argument<Int>("callTimes")
        if (callTimes == null) {
          result.error("400", "Invalid arguments", null)
          return
        }

        Thread {
          try {
            val printed = AppModule.feedLineUseCase.execute(callTimes)
            result.success(printed)
          } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
          }
        }.start()
      }
      "disconnectFromDevice" -> {
        Thread {
          try {
            val disconnected = AppModule.disconnectDeviceUseCase.execute()
            result.success(disconnected)
          } catch (e: Exception) {
            result.error("DISCONNECT_ERROR", e.message, null)
          }
        }.start()
      }
      "isConnected" -> {
        Thread {
          try {
            val connected = AppModule.isConnectedUseCase.execute()
            result.success(connected)
          } catch (e: Exception) {
            result.error("CONNECTION_CHECK_ERROR", e.message, null)
          }
        }.start()
      }
      "printImage" -> {
          val data = call.argument<ByteArray>("data")
          val align = call.argument<Int>("textAlign")

          if (data == null || align == null) {
            result.error("400", "Invalid arguments", null)
            return
          }

          Thread {
            try {
                val printed = AppModule.printImageUseCase.execute(data, align)
                result.success(printed)
            } catch (e: Exception) {
                result.error("PRINT_ERROR", e.message, null)
            }
          }.start()
        }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
