#ifndef FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_
#define FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_sink.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>

namespace gamepad_glyphs {

class GamepadGlyphsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GamepadGlyphsPlugin();
  explicit GamepadGlyphsPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~GamepadGlyphsPlugin();

  // Disallow copy and assign.
  GamepadGlyphsPlugin(const GamepadGlyphsPlugin&) = delete;
  GamepadGlyphsPlugin& operator=(const GamepadGlyphsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SetInputEventSink(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink);
  void ClearInputEventSink();
  void EmitInputEvent(unsigned long vendor_id, unsigned long product_id);
  void EmitKeyboardEvent();
  void PollGameControllers();
  void RegisterInputDevices(HWND window);

 private:
  std::optional<LRESULT> HandleWindowMessage(HWND hwnd,
                                             UINT message,
                                             WPARAM wparam,
                                             LPARAM lparam);

  flutter::PluginRegistrarWindows *registrar_;
  int window_proc_delegate_id_;
  HWND input_window_;
  bool input_devices_registered_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> input_event_sink_;
};

}  // namespace gamepad_glyphs

#endif  // FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_
