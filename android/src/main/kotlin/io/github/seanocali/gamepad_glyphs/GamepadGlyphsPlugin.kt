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
    private var detectMouse = false
    private var detectTouch = false

    private val inputListener = object : View.OnKeyListener, View.OnGenericMotionListener {
        override fun onKey(view: View, keyCode: Int, event: KeyEvent): Boolean {
            if (event.action != KeyEvent.ACTION_DOWN) return false
            val source = event.source
            val keyboard = (source and InputDevice.SOURCE_KEYBOARD) != 0
            val controller = source and (InputDevice.SOURCE_GAMEPAD or
                InputDevice.SOURCE_JOYSTICK or InputDevice.SOURCE_DPAD)
            val mouse = source and InputDevice.SOURCE_MOUSE
            when {
                keyboard -> emitInput(event.device, "keyboard")
                controller != 0 -> emitInput(event.device, "gamepad")
                detectMouse && mouse != 0 -> emitInput(event.device, "mouse")
            }
            return false
        }

        override fun onGenericMotion(view: View, event: MotionEvent): Boolean {
            val source = event.source
            val controller = source and (InputDevice.SOURCE_GAMEPAD or
                InputDevice.SOURCE_JOYSTICK or InputDevice.SOURCE_DPAD)
            if (controller != 0 && event.action == MotionEvent.ACTION_MOVE) {
                emitInput(event.device, "gamepad")
                return false
            }

            val mouse = source and InputDevice.SOURCE_MOUSE
            if (detectMouse && mouse != 0 && (event.action == MotionEvent.ACTION_MOVE ||
                    event.action == MotionEvent.ACTION_SCROLL ||
                    event.action == MotionEvent.ACTION_BUTTON_PRESS)) {
                emitInput(event.device, "mouse")
            }
            return false
        }
    }

    private val touchListener = View.OnTouchListener { _, event ->
        val touch = event.source and InputDevice.SOURCE_TOUCHSCREEN
        if (detectTouch && touch != 0 && event.action == MotionEvent.ACTION_DOWN) {
            emitInput(event.device, "touch")
        }
        false
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
        val options = arguments as? Map<*, *>
        detectMouse = options?.get("detectMouse") as? Boolean ?: false
        detectTouch = options?.get("detectTouch") as? Boolean ?: false
        eventSink = events
        attachInputListeners()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        detectMouse = false
        detectTouch = false
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
        view.setOnTouchListener(touchListener)
    }

    private fun detachInputListeners() {
        val view = activity?.window?.decorView ?: return
        view.setOnKeyListener(null)
        view.setOnGenericMotionListener(null)
        view.setOnTouchListener(null)
    }

    private fun emitInput(device: InputDevice?, kind: String) {
        val sink = eventSink ?: return
        if (kind == "keyboard" || device == null || device.isVirtual) {
            sink.success(mapOf(
                "vendorId" to null,
                "productId" to null,
                "kind" to kind,
            ))
            return
        }
        sink.success(mapOf(
            "vendorId" to device.vendorId,
            "productId" to device.productId,
            "kind" to kind,
        ))
    }
}
