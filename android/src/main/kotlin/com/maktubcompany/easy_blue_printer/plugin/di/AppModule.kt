package com.maktubcompany.easy_blue_printer.plugin.di

import com.maktubcompany.easy_blue_printer.plugin.data.datasource.BluetoothDataSource
import com.maktubcompany.easy_blue_printer.plugin.data.repository.BluetoothRepositoryImpl
import com.maktubcompany.easy_blue_printer.plugin.domain.repository.BluetoothRepository
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.ConnectDeviceUseCase
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.DeviceIsConneceted
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.DisconnectDeviceUseCase
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.FeedLineUseCase
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.PrintUseCase
import com.maktubcompany.easy_blue_printer.plugin.domain.usecase.ScanDevicesUseCase

object AppModule {
    private val bluetoothDataSource = BluetoothDataSource()
    private val bluetoothRepository: BluetoothRepository = BluetoothRepositoryImpl(bluetoothDataSource)

    val scanDevicesUseCase = ScanDevicesUseCase(bluetoothRepository)
    val connectDeviceUseCase = ConnectDeviceUseCase(bluetoothRepository)
    val printUseCase = PrintUseCase(bluetoothRepository)
    val disconnectDeviceUseCase = DisconnectDeviceUseCase(bluetoothRepository)
    val feedLineUseCase = FeedLineUseCase(bluetoothRepository)
    val isConnectedUseCase = DeviceIsConneceted(bluetoothRepository)
}