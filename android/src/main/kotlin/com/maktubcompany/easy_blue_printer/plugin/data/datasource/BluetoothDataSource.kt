package com.maktubcompany.easy_blue_printer.plugin.data.datasource

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.graphics.BitmapFactory
import android.util.Log
import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import com.maktubcompany.easy_blue_printer.plugin.utils.Utils
import java.io.IOException
import java.util.UUID


class BluetoothDataSource {
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var _device: BluetoothDeviceEntity? = null
    private var _socket: BluetoothSocket? = null
    var paperWidth: Int = 384

    fun configurePrinter(paperWidth: Int) {
        this.paperWidth = paperWidth
    }

    fun getPairedDevices(): List<BluetoothDeviceEntity> {
        return bluetoothAdapter?.bondedDevices
            ?.filter { !it.name.isNullOrBlank() && it.name != "Unknown" }
            ?.map { BluetoothDeviceEntity(it.name, it.address) }
            ?: emptyList()
    }


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
            /*if (_socket?.isConnected == false) {
                val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                _socket = m.invoke(device, 1) as BluetoothSocket
                _socket?.connect()
            }*/

            if (_socket?.isConnected == true) {
                _device = BluetoothDeviceEntity(device.name, device.address)
                true
            } else {
                false
            }
        } catch (e: IOException) {
            throw e
        }
    }

    fun printData(data: String, size: Int, align: Int, bold: Boolean): Boolean {
        return try {
            // Build complete command buffer before sending
            val alignBytes = when (align) {
                0 -> byteArrayOf(0x1B, 0x61, 0x00)
                1 -> byteArrayOf(0x1B, 0x61, 0x01)
                2 -> byteArrayOf(0x1B, 0x61, 0x02)
                else -> byteArrayOf()
            }
            val boldBytes = if (bold) byteArrayOf(0x1B, 0x47, 0x01) else byteArrayOf(0x1B, 0x47, 0x00)
            val sizeBytes = when (size) {
                0 -> byteArrayOf(0x1B, 0x21, 0x03)
                1 -> byteArrayOf(0x1B, 0x21, 0x08)
                2 -> byteArrayOf(0x1B, 0x21, 0x10)
                3 -> byteArrayOf(0x1B, 0x21, 0x30)
                else -> byteArrayOf()
            }
            val dataBytes = data.toByteArray()
            val command = alignBytes + boldBytes + sizeBytes + dataBytes + byteArrayOf(0x0A)

            // Send in chunks to avoid overflowing the printer buffer
            val chunkSize = 128
            var offset = 0
            while (offset < command.size) {
                val end = minOf(offset + chunkSize, command.size)
                _socket?.outputStream?.write(command, offset, end - offset)
                _socket?.outputStream?.flush()
                Thread.sleep(10)
                offset = end
            }

            true
        } catch (e: IOException) {
            throw e
        }
    }

    fun disconnectToDevice(): Boolean {
        return try {
            _socket?.close()
            _device = null
            _socket = null
            true
        } catch (e: IOException) {
            throw e
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
            throw e
        }
    }

    fun isConnected(): Boolean {
        // Verifica se o socket é nulo ou não está conectado inicialmente
        val socket = _socket ?: return false
        if (!socket.isConnected) return false

        return try {
            // Tenta escrever um comando "ping" sem efeito.
            // O comando 0x00 pode ser substituído por outro comando leve se necessário.
            socket.outputStream.write(byteArrayOf(0x00))
            socket.outputStream.flush()
            true
        } catch (e: IOException) {
            throw e
        }
    }

    fun printImage(data: ByteArray, align: Int): Boolean {
        return try {
            var bmp = BitmapFactory.decodeByteArray(data, 0, data.size)

            if (bmp != null) {

                bmp = Utils.scaleBitmapToWidth(bmp, paperWidth)

                val command: ByteArray = Utils.decodeBitmap(bmp) ?: return false

                val leftAlign = byteArrayOf(0x1B, 0x61, 0x00)
                val centerAlign = byteArrayOf(0x1B, 0x61, 0x01)
                val rightAlign = byteArrayOf(0x1B, 0x61, 0x02)

                when (align) {
                    0 -> _socket?.outputStream?.write(leftAlign)
                    1 -> _socket?.outputStream?.write(centerAlign)
                    2 -> _socket?.outputStream?.write(rightAlign)
                }

                // Send image data in chunks to avoid overflowing the BT buffer
                val chunkSize = 512
                var offset = 0
                while (offset < command.size) {
                    val end = minOf(offset + chunkSize, command.size)
                    _socket?.outputStream?.write(command, offset, end - offset)
                    _socket?.outputStream?.flush()
                    Thread.sleep(20)
                    offset = end
                }

                // Wait for the printer to finish processing the image
                Thread.sleep(200)

                // Feed empty lines for paper tear-off
                _socket?.outputStream?.write("\n\n\n\n".toByteArray())
                _socket?.outputStream?.flush()

                // Reset printer to text mode after image
                _socket?.outputStream?.write(byteArrayOf(0x1B, 0x40))
                _socket?.outputStream?.flush()

                true
            } else {
                Log.e("Print Photo error", "The file doesn't exist")
                false
            }
        } catch (e: IOException) {
            throw e
        }
    }
}