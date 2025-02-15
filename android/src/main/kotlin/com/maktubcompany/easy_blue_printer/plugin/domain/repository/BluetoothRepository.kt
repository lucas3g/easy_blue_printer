package com.maktubcompany.easy_blue_printer.plugin.domain.repository

import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity

interface BluetoothRepository {
    fun getPairedDevices(): List<BluetoothDeviceEntity>
    fun connectToDevice(address: String): Boolean
    fun disconnectToDevice(): Boolean
    fun printData(data: String, size: Int, align: Int, bold: Boolean): Boolean
    fun printEmptyLine(callTimes: Int): Boolean
    fun isConnected(): Boolean
}