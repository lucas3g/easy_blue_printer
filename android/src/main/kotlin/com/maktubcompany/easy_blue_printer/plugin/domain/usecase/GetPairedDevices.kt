package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class GetPairedDevices(private val repository: BluetoothRepository) {
    fun execute(): List<BluetoothDeviceEntity> {
        return repository.getPairedDevices()
    }
}