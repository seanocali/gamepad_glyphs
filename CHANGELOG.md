## 0.0.1

* Added the initial `GamepadGlyph` widget and semantic input mappings.
* Added keyboard, Xbox, PlayStation, Nintendo, and Valve SVG glyph assets.
* Added listenable last-input state and hardware-ID device mapping.
* Added Windows raw keyboard/HID input events through an `EventChannel`.
* Added XInput fallback detection for Xbox controllers.
* Added automatic input tracking for Linux, macOS, Android, iOS, and web.
* Added permission-free focused keyboard and pointer tracking on Linux.
* Ignored controller connection state, button releases, and analog noise when
  selecting the active glyph device.
* Converted the Xbox and PlayStation monochrome font glyphs to SVG assets.
