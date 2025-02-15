package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.entities.BluetoothDeviceEntity
import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class PrintImageUseCase(private val repository: BluetoothRepository) {
    fun execute(data: ByteArray, align: Int): Boolean {
        return repository.printImage(data, align)
    }
}