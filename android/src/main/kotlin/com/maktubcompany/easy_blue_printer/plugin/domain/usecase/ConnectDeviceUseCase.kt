package com.maktubcompany.easy_blue_printer.plugin.domain.usecase


import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository

class ConnectDeviceUseCase(private val repository: BluetoothRepository) {
    fun execute(address: String): Boolean {
        return repository.connectToDevice(address)
    }
}