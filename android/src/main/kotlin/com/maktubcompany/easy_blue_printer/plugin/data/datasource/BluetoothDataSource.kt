package com.maktubcompany.easy_blue_printer.plugin.data.datasource

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import java.io.IOException
import java.util.UUID

class BluetoothDataSource {
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var _device: BluetoothDeviceEntity? = null
    private var _socket: BluetoothSocket? = null

    @SuppressLint("MissingPermission")
    fun scanDevices(): List<BluetoothDeviceEntity> {
        return bluetoothAdapter?.bondedDevices?.map {
            BluetoothDeviceEntity(it.name, it.address)
        } ?: emptyList()
    }

    @SuppressLint("MissingPermission")
    fun connectToDevice(address: String): Boolean {
        val device = bluetoothAdapter?.bondedDevices?.find { it.address == address }
        val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        if (device == null) {
            return false
        }

        return try {
            bluetoothAdapter?.cancelDiscovery() // Cancela descoberta antes de criar o socket

            _socket = device.createRfcommSocketToServiceRecord(uuid)
            _socket?.connect() // Tenta conectar

            // Se não conectar, faz fallback para reflection
            if (_socket?.isConnected == false) {
                val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                _socket = m.invoke(device, 1) as BluetoothSocket
                _socket?.connect()
            }

            if (_socket?.isConnected == true) {
                _device = BluetoothDeviceEntity(device.name, device.address)
                true
            } else {
                false
            }
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    fun printData(data: String, size: Int, align: Int, bold: Boolean): Boolean {
        return try {
            val leftAlign = byteArrayOf(0x1B, 0x61, 0x00)
            val centerAlign = byteArrayOf(0x1B, 0x61, 0x01)
            val rightAlign = byteArrayOf(0x1B, 0x61, 0x02)

            when (align) {
                0 -> _socket?.outputStream?.write(leftAlign)
                1 -> _socket?.outputStream?.write(centerAlign)
                2 -> _socket?.outputStream?.write(rightAlign)
            }

            val boldOn = byteArrayOf(0x1B, 0x47, 0x01)  // Ativar duplicação de impressão (simula negrito)
            val boldOff = byteArrayOf(0x1B, 0x47, 0x00) // Desativar duplicação

            if (bold) {
                _socket?.outputStream?.write(boldOn)
            } else {
                _socket?.outputStream?.write(boldOff)
            }

            val normalSize = byteArrayOf(0x1B, 0x21, 0x03)
            val mediumSize = byteArrayOf(0x1B, 0x21, 0x10)
            val largeSize = byteArrayOf(0x1B, 0x21, 0x20)
            val hugeSize = byteArrayOf(0x1B, 0x21, 0x30)

            when (size) {
                0 -> _socket?.outputStream?.write(normalSize)
                1 -> _socket?.outputStream?.write(mediumSize)
                2 -> _socket?.outputStream?.write(largeSize)
                3 -> _socket?.outputStream?.write(hugeSize)
            }

            _socket?.outputStream?.write(data.toByteArray())

            _socket?.outputStream?.write("\n".toByteArray())

            _socket?.outputStream?.flush()

            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    fun disconnectToDevice(): Boolean {
        return try {
            _socket?.close()
            _device = null
            _socket = null
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    fun printEmptyLine(callTimes: Int): Boolean {
        return try {
            for (i in 0 until callTimes) {
                _socket?.outputStream?.write("\n".toByteArray())
            }

            _socket?.outputStream?.flush()

            true
        } catch (e: IOException) {
            e.printStackTrace()

            false
        }
    }

    fun isConnected(): Boolean {
        return _socket?.isConnected == true
    }
}