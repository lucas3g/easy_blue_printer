package com.maktubcompany.easy_blue_printer.plugin.utils

import android.graphics.Bitmap
import android.util.Log
import java.util.Locale

object Utils {
    // UNICODE 0x23 = #
    val UNICODE_TEXT: ByteArray = byteArrayOf(
        0x23, 0x23, 0x23,
        0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23,
        0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23, 0x23,
        0x23, 0x23, 0x23
    )

    private const val hexStr = "0123456789ABCDEF"
    private val binaryArray = arrayOf(
        "0000", "0001", "0010", "0011",
        "0100", "0101", "0110", "0111", "1000", "1001", "1010", "1011",
        "1100", "1101", "1110", "1111"
    )

    fun decodeBitmap(bmp: Bitmap): ByteArray? {
        val bmpWidth = bmp.width
        val bmpHeight = bmp.height

        val list: MutableList<String> = ArrayList() //binaryString list
        var sb: StringBuffer


        var bitLen = bmpWidth / 8
        val zeroCount = bmpWidth % 8

        var zeroStr = ""
        if (zeroCount > 0) {
            bitLen = bmpWidth / 8 + 1
            for (i in 0 until (8 - zeroCount)) {
                zeroStr = zeroStr + "0"
            }
        }

        for (i in 0 until bmpHeight) {
            sb = StringBuffer()
            for (j in 0 until bmpWidth) {
                val color = bmp.getPixel(j, i)

                val r = (color shr 16) and 0xff
                val g = (color shr 8) and 0xff
                val b = color and 0xff

                // if color close to white，bit='0', else bit='1'
                if (r > 160 && g > 160 && b > 160) sb.append("0")
                else sb.append("1")
            }
            if (zeroCount > 0) {
                sb.append(zeroStr)
            }
            list.add(sb.toString())
        }

        val bmpHexList = binaryListToHexStringList(list)

        // GS v 0 command header: 1D 76 30 00 xL xH yL yH
        // xL/xH = bytes per line (little-endian), yL/yH = height in lines (little-endian)
        val header = byteArrayOf(
            0x1D, 0x76, 0x30, 0x00,
            (bitLen and 0xFF).toByte(),
            ((bitLen shr 8) and 0xFF).toByte(),
            (bmpHeight and 0xFF).toByte(),
            ((bmpHeight shr 8) and 0xFF).toByte()
        )

        val rasterData = hexList2Byte(bmpHexList)
        val result = ByteArray(header.size + rasterData.size)
        System.arraycopy(header, 0, result, 0, header.size)
        System.arraycopy(rasterData, 0, result, header.size, rasterData.size)

        return result
    }

    fun binaryListToHexStringList(list: List<String>): List<String> {
        val hexList: MutableList<String> = ArrayList()
        for (binaryStr in list) {
            val sb = StringBuffer()
            var i = 0
            while (i < binaryStr.length) {
                val str = binaryStr.substring(i, i + 8)

                val hexString = myBinaryStrToHexString(str)
                sb.append(hexString)
                i += 8
            }
            hexList.add(sb.toString())
        }
        return hexList
    }

    fun myBinaryStrToHexString(binaryStr: String): String {
        var hex = ""
        val f4 = binaryStr.substring(0, 4)
        val b4 = binaryStr.substring(4, 8)
        for (i in binaryArray.indices) {
            if (f4 == binaryArray[i]) hex += hexStr.substring(i, i + 1)
        }
        for (i in binaryArray.indices) {
            if (b4 == binaryArray[i]) hex += hexStr.substring(i, i + 1)
        }

        return hex
    }

    fun hexList2Byte(list: List<String>): ByteArray {
        val commandList: MutableList<ByteArray?> = ArrayList()

        for (hexStr in list) {
            commandList.add(hexStringToBytes(hexStr))
        }
        val bytes = sysCopy(commandList)
        return bytes
    }

    fun hexStringToBytes(hexString: String?): ByteArray? {
        var hexString = hexString
        if (hexString == null || hexString == "") {
            return null
        }
        hexString = hexString.uppercase(Locale.getDefault())
        val length = hexString.length / 2
        val hexChars = hexString.toCharArray()
        val d = ByteArray(length)
        for (i in 0 until length) {
            val pos = i * 2
            d[i] =
                (charToByte(hexChars[pos]).toInt() shl 4 or charToByte(hexChars[pos + 1]).toInt()).toByte()
        }
        return d
    }

    fun sysCopy(srcArrays: MutableList<ByteArray?>): ByteArray {
        var len = 0
        for (srcArray in srcArrays) {
            len += srcArray?.size ?: 0
        }
        val destArray = ByteArray(len)
        var destLen = 0
        for (srcArray in srcArrays) {
            if (srcArray != null) {
                System.arraycopy(srcArray, 0, destArray, destLen, srcArray.size)
            }
            destLen += srcArray?.size ?: 0
        }
        return destArray
    }

    private fun charToByte(c: Char): Byte {
        return "0123456789ABCDEF".indexOf(c).toByte()
    }

    fun scaleBitmapToWidth(bitmap: Bitmap, targetWidth: Int): Bitmap {
        val aspectRatio = bitmap.height.toFloat() / bitmap.width.toFloat()
        val targetHeight = (targetWidth * aspectRatio).toInt()

        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }
}