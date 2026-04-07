package com.maktubcompany.easy_blue_printer.plugin.data.datasource

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.graphics.BitmapFactory
import android.util.Log
import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import com.maktubcompany.easy_blue_printer.plugin.utils.Utils
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.UUID


class BluetoothDataSource {
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()

    private var _device: BluetoothDeviceEntity? = null
    private var _socket: BluetoothSocket? = null
    var paperWidth: Int = 384

    // Accumulates ESC/POS bytes from printData/printEmptyLine calls.
    // All buffered data is sent as one continuous stream when commitPrint,
    // printEmptyLine, or printImage is called.
    private val printBuffer = ByteArrayOutputStream()

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
            bluetoothAdapter?.cancelDiscovery()

            _socket = device.createRfcommSocketToServiceRecord(uuid)
            _socket?.connect()

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

    // Builds ESC/POS bytes and appends to printBuffer — no network IO.
    // Data is only sent when commitPrint(), printEmptyLine(), or printImage() is called.
    fun printData(data: String, size: Int, align: Int, bold: Boolean): Boolean {
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
        printBuffer.write(alignBytes)
        printBuffer.write(boldBytes)
        printBuffer.write(sizeBytes)
        printBuffer.write(data.toByteArray())
        printBuffer.write(byteArrayOf(0x0A))
        return true
    }

    // Appends newlines to buffer. The buffer is flushed by commitPrint()
    // when the Dart queue empties, or by printImage() before image data.
    fun printEmptyLine(callTimes: Int): Boolean {
        val newlines = ByteArray(callTimes) { 0x0A }
        printBuffer.write(newlines)
        return true
    }

    // Sends all buffered bytes to the printer. Called by the Dart queue
    // when all enqueued jobs are done (handles text-only receipts).
    fun commitPrint(): Boolean {
        return flushPrintBuffer()
    }

    // Sends buffered bytes as one continuous stream in 512-byte chunks
    // with 20ms between each chunk — same rate used for image data.
    private fun flushPrintBuffer(): Boolean {
        val bytes = printBuffer.toByteArray()
        printBuffer.reset()
        if (bytes.isEmpty()) return true
        return sendChunked(bytes)
    }

    private fun sendChunked(bytes: ByteArray): Boolean {
        return try {
            val chunkSize = 512
            var offset = 0
            while (offset < bytes.size) {
                val end = minOf(offset + chunkSize, bytes.size)
                _socket?.outputStream?.write(bytes, offset, end - offset)
                _socket?.outputStream?.flush()
                Thread.sleep(20)
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
            printBuffer.reset()
            true
        } catch (e: IOException) {
            throw e
        }
    }

    fun isConnected(): Boolean {
        val socket = _socket ?: return false
        if (!socket.isConnected) return false

        return try {
            socket.outputStream.write(byteArrayOf(0x00))
            socket.outputStream.flush()
            true
        } catch (e: IOException) {
            throw e
        }
    }

    // Encodes the image to ESC/POS bytes and appends them to printBuffer.
    // No socket IO happens here — everything is sent as one continuous stream
    // by commitPrint(), together with any preceding and following text.
    fun printImage(data: ByteArray, align: Int): Boolean {
        var bmp = BitmapFactory.decodeByteArray(data, 0, data.size)

        if (bmp != null) {
            bmp = Utils.scaleBitmapToWidth(bmp, paperWidth)

            val command: ByteArray = Utils.decodeBitmap(bmp) ?: return false

            val alignBytes = when (align) {
                0 -> byteArrayOf(0x1B, 0x61, 0x00)
                1 -> byteArrayOf(0x1B, 0x61, 0x01)
                2 -> byteArrayOf(0x1B, 0x61, 0x02)
                else -> byteArrayOf()
            }
            printBuffer.write(alignBytes)
            printBuffer.write(command)
            // Paper feed for tear-off
            printBuffer.write(byteArrayOf(0x0A, 0x0A, 0x0A, 0x0A))
            // Reset printer to text mode so subsequent text commands work correctly
            printBuffer.write(byteArrayOf(0x1B, 0x40))
            return true
        } else {
            Log.e("Print Photo error", "The file doesn't exist")
            return false
        }
    }
}
