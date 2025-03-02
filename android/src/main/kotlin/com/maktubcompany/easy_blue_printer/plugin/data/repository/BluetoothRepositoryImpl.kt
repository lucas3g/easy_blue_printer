package com.maktubcompany.easy_blue_printer.plugin.data.repository

import com.maktubcompany.easy_blue_printer.plugin.data.datasource.BluetoothDataSource
import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class BluetoothRepositoryImpl(
    private val dataSource: BluetoothDataSource
) : BluetoothRepository {

    override fun getPairedDevices(): List<BluetoothDeviceEntity> {
        return dataSource.getPairedDevices()
    }

    override fun connectToDevice(address: String): Boolean {
        return dataSource.connectToDevice(address)
    }

    override fun disconnectToDevice(): Boolean {
        return dataSource.disconnectToDevice()
    }

    override fun printData(data: String, size: Int, align: Int, bold: Boolean): Boolean {
        return dataSource.printData(data, size, align, bold)
    }

    override fun printEmptyLine(callTimes: Int): Boolean {
       return dataSource.printEmptyLine(callTimes)
    }

    override fun isConnected(): Boolean {
        return dataSource.isConnected()
    }

    override fun printImage(data: ByteArray, align: Int): Boolean {
        return dataSource.printImage(data, align)
    }
}