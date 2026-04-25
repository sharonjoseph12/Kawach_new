package com.kawach.kawach

import android.view.KeyEvent
import android.telephony.SmsManager
import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private var volumeButtonCount = 0
    private var lastVolumePressTime: Long = 0
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val blePlugin = BleMeshPlugin(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kawach/ble_mesh_methods").setMethodCallHandler(blePlugin)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kawach/ble_mesh_events").setStreamHandler(blePlugin)


        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kawach/hardware_trigger")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kawach/sms").setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                
                if (phone != null && message != null) {
                    try {
                        val smsManager = SmsManager.getDefault()
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone or message null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kawach/stealth").setMethodCallHandler { call, result ->
            if (call.method == "enableStealth") {
                val enable = call.argument<Boolean>("enable") ?: false
                try {
                    val pm = context.packageManager
                    val normalComponent = ComponentName(context, "com.kawach.kawach.MainActivity")
                    val stealthComponent = ComponentName(context, "com.kawach.kawach.CalculatorActivity")
                    
                    if (enable) {
                        pm.setComponentEnabledSetting(normalComponent, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
                        pm.setComponentEnabledSetting(stealthComponent, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                    } else {
                        pm.setComponentEnabledSetting(stealthComponent, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
                        pm.setComponentEnabledSetting(normalComponent, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STEALTH_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastVolumePressTime < 2000) {
                volumeButtonCount++
            } else {
                volumeButtonCount = 1
            }
            lastVolumePressTime = currentTime

            if (volumeButtonCount >= 3) {
                eventSink?.success(volumeButtonCount)
                volumeButtonCount = 0 // Reset after trigger
            }
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
