package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class PrintUseCase(private val repository: BluetoothRepository) {
    fun execute(data: String, size: Int, align: Int, bold: Boolean): Boolean {
        return repository.printData(data, size, align, bold)
    }
}