package io.github.seanocali.gamepad_glyphs

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View

/** GamepadGlyphsPlugin */
class GamepadGlyphsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null

    private val inputListener = object : View.OnKeyListener, View.OnGenericMotionListener {
        override fun onKey(view: View, keyCode: Int, event: KeyEvent): Boolean {
            if (event.action != KeyEvent.ACTION_DOWN) return false
            val keyboard = (event.source and InputDevice.SOURCE_KEYBOARD) != 0
            emitInput(event.device, keyboard)
            return false
        }

        override fun onGenericMotion(view: View, event: MotionEvent): Boolean {
            val source = event.source
            val controller = source and (InputDevice.SOURCE_GAMEPAD or
                InputDevice.SOURCE_JOYSTICK or InputDevice.SOURCE_DPAD)
            if (controller == 0 || event.action != MotionEvent.ACTION_MOVE) return false
            emitInput(event.device, false)
            return false
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gamepad_glyphs")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "gamepad_glyphs/input_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachInputListeners()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        attachInputListeners()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        detachInputListeners()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        attachInputListeners()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachInputListeners()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        attachInputListeners()
    }

    override fun onDetachedFromActivity() {
        detachInputListeners()
        activity = null
    }

    private fun attachInputListeners() {
        val view = activity?.window?.decorView ?: return
        view.setOnKeyListener(inputListener)
        view.setOnGenericMotionListener(inputListener)
    }

    private fun detachInputListeners() {
        val view = activity?.window?.decorView ?: return
        view.setOnKeyListener(null)
        view.setOnGenericMotionListener(null)
    }

    private fun emitInput(device: InputDevice?, keyboard: Boolean) {
        val sink = eventSink ?: return
        if (keyboard || device == null || device.isVirtual) {
            sink.success(mapOf("vendorId" to null, "productId" to null))
            return
        }
        sink.success(mapOf("vendorId" to device.vendorId, "productId" to device.productId))
    }
}
