//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <gamepad_glyphs/gamepad_glyphs_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) gamepad_glyphs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "GamepadGlyphsPlugin");
  gamepad_glyphs_plugin_register_with_registrar(gamepad_glyphs_registrar);
}
