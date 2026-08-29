#include <flutter_linux/flutter_linux.h>

#include "include/gamepad_glyphs/gamepad_glyphs_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Handles the getPlatformVersion method call.
FlMethodResponse *get_platform_version();

// Returns whether an absolute controller axis moved beyond its dead zone.
bool controller_axis_is_active(int baseline_value, int current_value,
                               int dead_zone);
