#include "include/gamepad_glyphs/gamepad_glyphs_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "gamepad_glyphs_plugin.h"

void GamepadGlyphsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  gamepad_glyphs::GamepadGlyphsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
