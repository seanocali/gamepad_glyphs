package io.github.seanocali.gamepad_glyphs

import android.view.InputDevice
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class GamepadGlyphsPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = GamepadGlyphsPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun controllerAxis_requiresMovementPastItsDeadZone() {
        assertFalse(controllerAxisIsActive(-1f, 1f, 0.05f, 0.01f, 0f))
        assertFalse(controllerAxisIsActive(-1f, 1f, 0.05f, 0.01f, 0.1f))
        assertTrue(controllerAxisIsActive(-1f, 1f, 0.05f, 0.01f, 0.11f))
    }

    @Test
    fun controllerTrigger_usesItsReleasedEndpointAsNeutral() {
        assertFalse(controllerAxisIsActive(0f, 1f, 0f, 0f, 0.1f))
        assertTrue(controllerAxisIsActive(0f, 1f, 0f, 0f, 0.11f))
    }

    @Test
    fun gamepadButtonSource_isNotMistakenForKeyboard() {
        assertTrue(sourceIncludes(InputDevice.SOURCE_GAMEPAD, InputDevice.SOURCE_GAMEPAD))
        assertFalse(sourceIncludes(InputDevice.SOURCE_GAMEPAD, InputDevice.SOURCE_KEYBOARD))
    }
}
