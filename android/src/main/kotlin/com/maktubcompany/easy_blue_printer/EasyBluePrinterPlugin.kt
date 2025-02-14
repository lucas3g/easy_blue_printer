package com.maktubcompany.easy_blue_printer

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.maktubcompany.easy_blue_printer.plugin.di.AppModule
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

/** EasyBluePrinterPlugin */
class EasyBluePrinterPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private val scope = MainScope() // Escopo de coroutine para o plugin

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "scanDevices" -> {
        scope.launch {
          try {
            val devices = withContext(Dispatchers.IO) {
              AppModule.scanDevicesUseCase.execute().map { "${it.name} (${it.address})" }
            }
            result.success(devices)
          } catch (e: Exception) {
            result.error("SCAN_ERROR", e.message, null)
          }
        }
      }
      "connectToDevice" -> {
        val address = call.argument<String>("address")
        if (address == null) {
          result.error("400", "Address is required", null)
          return
        }

        scope.launch {
          try {
            val connected = withContext(Dispatchers.IO) {
              AppModule.connectDeviceUseCase.execute(address)
            }
            result.success(connected)
          } catch (e: Exception) {
            result.error("CONNECTION_ERROR", e.message, null)
          }
        }
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

        scope.launch {
          try {
            val printed = withContext(Dispatchers.IO) {
              AppModule.printUseCase.execute(data, fontSize, align, bold)
            }
            result.success(printed)
          } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
          }
        }
      }
      "printEmptyLine" -> {
        val callTimes = call.argument<Int>("callTimes")
        if (callTimes == null) {
          result.error("400", "Invalid arguments", null)
          return
        }

        scope.launch {
          try {
            val printed = withContext(Dispatchers.IO) {
              AppModule.feedLineUseCase.execute(callTimes)
            }
            result.success(printed)
          } catch (e: Exception) {
            result.error("PRINT_ERROR", e.message, null)
          }
        }
      }
      "disconnectFromDevice" -> {
        scope.launch {
          try {
            val disconnected = withContext(Dispatchers.IO) {
              AppModule.disconnectDeviceUseCase.execute()
            }
            result.success(disconnected)
          } catch (e: Exception) {
            result.error("DISCONNECT_ERROR", e.message, null)
          }
        }
      }
      "isConnected" -> {
        scope.launch {
          try {
            val connected = withContext(Dispatchers.IO) {
              AppModule.isConnectedUseCase.execute()
            }
            result.success(connected)
          } catch (e: Exception) {
            result.error("CONNECTION_CHECK_ERROR", e.message, null)
          }
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
