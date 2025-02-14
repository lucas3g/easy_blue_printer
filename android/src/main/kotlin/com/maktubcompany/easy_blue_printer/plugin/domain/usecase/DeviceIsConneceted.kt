package com.maktubcompany.easy_blue_printer.plugin.domain.usecase

import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class DeviceIsConneceted(private val repository: BluetoothRepository) {
    fun execute(): Boolean {
        return repository.isConnected()
    }
}