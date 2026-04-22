package com.kawach.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class BleMeshPlugin(private val context: Context) {
    companion object {
        const val TAG = "BleMeshPlugin"
        // Kawach specific UUID for BLE mesh
        val KAWACH_SERVICE_UUID: ParcelUuid = ParcelUuid.fromString("0000FEAA-0000-1000-8000-00805F9B34FB")
        const val METHOD_CHANNEL = "kawach/ble_mesh_methods"
        const val EVENT_CHANNEL = "kawach/ble_mesh_events"
    }

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null

    private var eventSink: EventChannel.EventSink? = null

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.d(TAG, "BLE Advertising started successfully")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "BLE Advertising failed with code: $errorCode")
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val record = result.scanRecord ?: return
            val serviceData = record.serviceData[KAWACH_SERVICE_UUID]
            
            if (serviceData != null) {
                // Convert bytes to Base64 string for Flutter
                val base64Data = android.util.Base64.encodeToString(serviceData, android.util.Base64.NO_WRAP)
                eventSink?.success(base64Data)
            }
        }
    }

    fun setupChannels(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdvertising" -> {
                    val payload = call.argument<String>("payload")
                    if (payload != null) {
                        val success = startAdvertising(payload)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARG", "Payload cannot be null", null)
                    }
                }
                "stopAdvertising" -> {
                    stopAdvertising()
                    result.success(true)
                }
                "startScanning" -> {
                    val success = startScanning()
                    result.success(success)
                }
                "stopScanning" -> {
                    stopScanning()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun startAdvertising(payloadBase64: String): Boolean {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) return false
        
        advertiser = bluetoothAdapter.bluetoothLeAdvertiser
        if (advertiser == null) return false

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(false)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val serviceData = android.util.Base64.decode(payloadBase64, android.util.Base64.NO_WRAP)
        
        val data = AdvertiseData.Builder()
            .addServiceUuid(KAWACH_SERVICE_UUID)
            .addServiceData(KAWACH_SERVICE_UUID, serviceData)
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .build()

        try {
            advertiser?.startAdvertising(settings, data, advertiseCallback)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start advertising", e)
            return false
        }
    }

    private fun stopAdvertising() {
        try {
            advertiser?.stopAdvertising(advertiseCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop advertising", e)
        }
    }

    private fun startScanning(): Boolean {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) return false
        
        scanner = bluetoothAdapter.bluetoothLeScanner
        if (scanner == null) return false

        val filter = ScanFilter.Builder()
            .setServiceUuid(KAWACH_SERVICE_UUID)
            .build()

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        try {
            scanner?.startScan(listOf(filter), settings, scanCallback)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start scanning", e)
            return false
        }
    }

    private fun stopScanning() {
        try {
            scanner?.stopScan(scanCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop scanning", e)
        }
    }
}
