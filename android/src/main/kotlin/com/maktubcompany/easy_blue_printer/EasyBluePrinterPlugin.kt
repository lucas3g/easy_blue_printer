package com.maktubcompany.easy_blue_printer

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.maktubcompany.easy_blue_printer.plugin.di.AppModule
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** EasyBluePrinterPlugin */
class EasyBluePrinterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_blue_printer")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "requestBluetoothPermissions" -> {
        if (activity != null) {
          requestBluetoothPermissions(result)
        } else {
          result.error("ACTIVITY_NULL", "Activity is null. Cannot request permissions.", null)
        }
      }

      "getPairedDevices" -> {
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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
        if (!hasBluetoothPermissions()) {
          result.error("PERMISSION_DENIED", "Bluetooth permissions are required", null)
          return
        }

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


  private fun hasBluetoothPermissions(): Boolean {
    if (activity == null) return false

    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12+
      ContextCompat.checkSelfPermission(activity!!, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
              ContextCompat.checkSelfPermission(activity!!, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
    } else {
      true // Android 11 ou inferior
    }
  }

  private fun requestBluetoothPermissions(result: Result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ActivityCompat.requestPermissions(
        activity!!,
        arrayOf(
          Manifest.permission.BLUETOOTH_CONNECT,
          Manifest.permission.BLUETOOTH_SCAN
        ),
        BLUETOOTH_PERMISSION_REQUEST_CODE
      )
      result.success("Solicitação de permissões enviada")
    } else {
      result.success("Permissões não são necessárias para esta versão do Android")
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }


  companion object {
    private const val BLUETOOTH_PERMISSION_REQUEST_CODE = 101
  }

}
