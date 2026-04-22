package com.kawach.app

import android.os.Bundle
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask
import android.content.ComponentName
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    companion object {
        private const val POWER_CHANNEL = "kawach/power_button"
        private const val INTERACTION_CHANNEL = "kawach/last_interaction"
    }

    private var powerPressCount = 0
    private var lastPowerPress = 0L
    private var powerResetTimer: Timer? = null

    // Volume SOS State
    private val volumeSequence = mutableListOf<Int>()
    private var lastVolumePressTime = 0L

    private var powerEventSink: EventChannel.EventSink? = null
    private var interactionChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Power button EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    powerEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    powerEventSink = null
                }
            })

        // Last interaction MethodChannel
        interactionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INTERACTION_CHANNEL
        )

        // Native BLE Mesh
        val bleMeshPlugin = BleMeshPlugin(this)
        bleMeshPlugin.setupChannels(flutterEngine.dartExecutor.binaryMessenger)

        // Screen Pinning / Lock Task Mode
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kawach/screen_pinning"
        ).setMethodCallHandler { call, result ->
            if (call.method == "pinScreen") {
                try {
                    startLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PIN_FAILED", e.message, null)
                }
            } else if (call.method == "unpinScreen") {
                try {
                    stopLockTask()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNPIN_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Camouflage Mode / App Disguise
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kawach/camouflage"
        ).setMethodCallHandler { call, result ->
            if (call.method == "setCamouflage") {
                try {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val pm = applicationContext.packageManager
                    val mainActivity = ComponentName(applicationContext, MainActivity::class.java)
                    val calculatorAlias = ComponentName(applicationContext, "com.kawach.app.CalculatorActivity")

                    if (enable) {
                        pm.setComponentEnabledSetting(calculatorAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                        pm.setComponentEnabledSetting(mainActivity, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
                    } else {
                        pm.setComponentEnabledSetting(mainActivity, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
                        pm.setComponentEnabledSetting(calculatorAlias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CAMOUFLAGE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_POWER) {
            val now = System.currentTimeMillis()
            if (now - lastPowerPress < 2000) {
                powerPressCount++
            } else {
                powerPressCount = 1
            }
            lastPowerPress = now

            powerResetTimer?.cancel()
            powerResetTimer = Timer()
            powerResetTimer?.schedule(object : TimerTask() {
                override fun run() {
                    powerPressCount = 0
                }
            }, 2000)

            if (powerPressCount >= 5) {
                powerPressCount = 0
                runOnUiThread {
                    powerEventSink?.success("sos_trigger")
                }
                return true
            }
        } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            val now = System.currentTimeMillis()
            if (now - lastVolumePressTime > 3000) {
                volumeSequence.clear()
            }
            lastVolumePressTime = now
            volumeSequence.add(keyCode)

            // Sequence: Down, Up, Down, Up (4 presses)
            if (volumeSequence.size >= 4) {
                val lastFour = volumeSequence.takeLast(4)
                if (lastFour == listOf(
                        KeyEvent.KEYCODE_VOLUME_DOWN,
                        KeyEvent.KEYCODE_VOLUME_UP,
                        KeyEvent.KEYCODE_VOLUME_DOWN,
                        KeyEvent.KEYCODE_VOLUME_UP
                    )) {
                    volumeSequence.clear()
                    runOnUiThread {
                        powerEventSink?.success("sos_trigger")
                    }
                    return true
                }
            }
            return super.onKeyDown(keyCode, event)
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onUserInteraction() {
        super.onUserInteraction()
        interactionChannel?.invokeMethod("onInteraction", System.currentTimeMillis())
    }
}
