package com.kawach.kawach

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*

@SuppressLint("MissingPermission")
class BleMeshPlugin(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val bluetoothManager: BluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter

    private var gattServer: BluetoothGattServer? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null

    private var eventSink: EventChannel.EventSink? = null

    companion object {
        val SERVICE_UUID: UUID = UUID.fromString("0000aaaa-0000-1000-8000-00805f9b34fb")
        val CHAR_UUID: UUID = UUID.fromString("0000bbbb-0000-1000-8000-00805f9b34fb")
        const val TAG = "BleMeshPlugin"
    }

    private var currentPayload: ByteArray = ByteArray(0)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled or unsupported", null)
            return
        }

        when (call.method) {
            "startAdvertising" -> {
                val base64Payload = call.argument<String>("payload")
                if (base64Payload != null) {
                    currentPayload = Base64.getDecoder().decode(base64Payload)
                    startGattServerAndAdvertise()
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Payload missing", null)
                }
            }
            "stopAdvertising" -> {
                stopAdvertising()
                result.success(true)
            }
            "startScanning" -> {
                startScanning()
                result.success(true)
            }
            "stopScanning" -> {
                stopScanning()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startGattServerAndAdvertise() {
        if (gattServer != null) return

        val serverCallback = object : BluetoothGattServerCallback() {
            override fun onCharacteristicReadRequest(
                device: BluetoothDevice?,
                requestId: Int,
                offset: Int,
                characteristic: BluetoothGattCharacteristic?
            ) {
                if (characteristic?.uuid == CHAR_UUID) {
                    val value = currentPayload.copyOfRange(offset.coerceAtMost(currentPayload.size), currentPayload.size)
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                } else {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_REQUEST_NOT_SUPPORTED, offset, null)
                }
            }
        }

        gattServer = bluetoothManager.openGattServer(context, serverCallback)
        
        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val characteristic = BluetoothGattCharacteristic(
            CHAR_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        service.addCharacteristic(characteristic)
        gattServer?.addService(service)

        // Start Advertiser
        advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.i(TAG, "BLE Advertise Started")
        }
        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "BLE Advertise Failed: \$errorCode")
        }
    }

    private fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
        gattServer?.close()
        gattServer = null
    }

    private fun startScanning() {
        scanner = bluetoothAdapter?.bluetoothLeScanner
        val filters = listOf(ScanFilter.Builder().setServiceUuid(ParcelUuid(SERVICE_UUID)).build())
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
            .build()
            
        scanner?.startScan(filters, settings, scanCallback)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            val device = result?.device ?: return
            
            // Connect to read payload
            device.connectGatt(context, false, object : BluetoothGattCallback() {
                override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        gatt?.discoverServices()
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        gatt?.close()
                    }
                }

                override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        val characteristic = gatt?.getService(SERVICE_UUID)?.getCharacteristic(CHAR_UUID)
                        if (characteristic != null) {
                            gatt.readCharacteristic(characteristic)
                        }
                    }
                }

                override fun onCharacteristicRead(
                    gatt: BluetoothGatt?,
                    characteristic: BluetoothGattCharacteristic?,
                    status: Int
                ) {
                    if (status == BluetoothGatt.GATT_SUCCESS && characteristic?.uuid == CHAR_UUID) {
                        val value = characteristic.value
                        if (value != null) {
                            val base64 = Base64.getEncoder().encodeToString(value)
                            eventSink?.success(base64)
                        }
                        gatt?.disconnect() // Disconnect after reading
                    }
                }
            })
        }
    }

    private fun stopScanning() {
        scanner?.stopScan(scanCallback)
    }
}
