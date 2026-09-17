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

    /// O aquecimento pedido pelo chamador, guardado porque o `ESC @` no fim de
    /// cada imagem o apaga e ele precisa ser reposto. `null` mantém o de
    /// fábrica e não manda comando nenhum.
    private var heatingTime: Int? = null

    // Accumulates ESC/POS bytes from printData/printEmptyLine calls.
    // All buffered data is sent as one continuous stream when commitPrint,
    // printEmptyLine, or printImage is called.
    private val printBuffer = ByteArrayOutputStream()

    private companion object {
        const val CHUNK_SIZE = 512

        /// Quantos bytes de raster a impressora consome por segundo.
        ///
        /// Uma térmica de 80mm a 203 dpi imprime cerca de 50 mm/s, ou seja
        /// ~400 linhas/s; a 72 bytes por linha dá ~28 KB/s. O valor é
        /// deliberadamente conservador: o custo de errar para menos é uma
        /// impressão mais lenta, e para mais é o buffer estourar e o papel
        /// sair com lixo.
        const val BYTES_PER_SECOND = 28_800L
    }

    fun configurePrinter(paperWidth: Int, heatingTime: Int?) {
        this.paperWidth = paperWidth
        this.heatingTime = heatingTime
        writeHeating()
    }

    /// `ESC 7 n1 n2 n3`: pontos simultâneos, tempo de aquecimento e intervalo.
    /// Só o tempo muda — é ele que escurece o traço. Vai para o buffer como
    /// qualquer outro comando, então só chega à impressora no próximo envio;
    /// mandar agora exigiria um socket que pode nem existir ainda quando a
    /// bobina é configurada.
    private fun writeHeating() {
        val heatingTime = this.heatingTime ?: return
        printBuffer.write(
            byteArrayOf(0x1B, 0x37, 0x07, (heatingTime and 0xFF).toByte(), 0x02)
        )
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

    // Sends buffered bytes as one continuous stream, paced to the speed the
    // paper actually comes out — same rate used for image data.
    private fun flushPrintBuffer(): Boolean {
        val bytes = printBuffer.toByteArray()
        printBuffer.reset()
        if (bytes.isEmpty()) return true
        return sendChunked(bytes)
    }

    private fun sendChunked(bytes: ByteArray): Boolean {
        val chunkSize = CHUNK_SIZE
        // O ritmo acompanha a velocidade do papel, e não um número fixo por
        // chunk: alimentar mais devagar que a impressão só faz a impressora
        // esperar, e mais rápido enche o buffer dela — que é o que fazia o
        // raster ser abandonado no meio.
        val delayMs = (chunkSize * 1000L / BYTES_PER_SECOND).coerceAtLeast(1L)
        var offset = 0
        while (offset < bytes.size) {
            if (_socket?.isConnected != true) throw IOException("Socket desconectado durante envio")
            val end = minOf(offset + chunkSize, bytes.size)
            val outputStream = _socket!!.outputStream
            var attempt = 0
            while (true) {
                try {
                    outputStream.write(bytes, offset, end - offset)
                    outputStream.flush()
                    break
                } catch (e: IOException) {
                    if (attempt >= 2) throw e
                    attempt++
                    Thread.sleep(delayMs * attempt)
                }
            }
            Thread.sleep(delayMs)
            offset = end
        }
        return true
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
            // O `ESC @` inicializa a impressora, e isso zera também o
            // aquecimento do `ESC 7`. Sem repor aqui, um documento fatiado
            // imprime a primeira fatia na densidade pedida e todas as outras
            // na de fábrica — o papel sai mais fraco da emenda para baixo.
            writeHeating()
            return true
        } else {
            Log.e("Print Photo error", "The file doesn't exist")
            return false
        }
    }
}
