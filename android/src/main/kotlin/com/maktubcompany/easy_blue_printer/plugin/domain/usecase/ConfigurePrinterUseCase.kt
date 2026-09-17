package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class ConfigurePrinterUseCase(private val repository: BluetoothRepository) {
    fun execute(paperWidth: Int, heatingTime: Int?) {
        repository.configurePrinter(paperWidth, heatingTime)
    }
}
