#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "gamepad_glyphs_plugin.h"

namespace gamepad_glyphs {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(GamepadGlyphsPlugin, GetPlatformVersion) {
  GamepadGlyphsPlugin plugin;
  // Save the reply value from the success callback.
  std::string result_string;
  plugin.HandleMethodCall(
      MethodCall("getPlatformVersion", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&result_string](const EncodableValue* result) {
            result_string = std::get<std::string>(*result);
          },
          nullptr, nullptr));

  // Since the exact string varies by host, just ensure that it's a string
  // with the expected format.
  EXPECT_TRUE(result_string.rfind("Windows ", 0) == 0);
}

TEST(GamepadGlyphsPlugin, ControllerStateTreatsFirstSampleAsBaseline) {
  ControllerInputState state;

  EXPECT_FALSE(UpdateControllerInputState(&state, {1}, {0.04}));
  EXPECT_FALSE(UpdateControllerInputState(&state, {0}, {0.0}));
  EXPECT_TRUE(UpdateControllerInputState(&state, {1}, {0.0}));
}

TEST(GamepadGlyphsPlugin, ControllerStateAccumulatesAxisMovement) {
  ControllerInputState state;

  EXPECT_FALSE(UpdateControllerInputState(&state, {}, {0.0}));
  EXPECT_FALSE(UpdateControllerInputState(&state, {}, {0.06}));
  EXPECT_TRUE(UpdateControllerInputState(&state, {}, {0.11}));
}

}  // namespace test
}  // namespace gamepad_glyphs
