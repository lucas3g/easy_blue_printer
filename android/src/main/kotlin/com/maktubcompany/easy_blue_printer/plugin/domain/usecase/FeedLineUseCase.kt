package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class FeedLineUseCase(private val repository: BluetoothRepository) {
    fun execute(callTimes: Int): Boolean {
        return repository.printEmptyLine(callTimes)
    }
}