#ifndef FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_
#define FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace gamepad_glyphs {

class GamepadGlyphsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GamepadGlyphsPlugin();

  virtual ~GamepadGlyphsPlugin();

  // Disallow copy and assign.
  GamepadGlyphsPlugin(const GamepadGlyphsPlugin&) = delete;
  GamepadGlyphsPlugin& operator=(const GamepadGlyphsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace gamepad_glyphs

#endif  // FLUTTER_PLUGIN_GAMEPAD_GLYPHS_PLUGIN_H_
