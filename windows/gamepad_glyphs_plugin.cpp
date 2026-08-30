#include "gamepad_glyphs_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <VersionHelpers.h>

#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Gaming.Input.h>

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdint>
#include <memory>
#include <optional>
#include <sstream>
#include <unordered_set>
#include <vector>

namespace gamepad_glyphs {

namespace {

constexpr UINT_PTR kControllerPollingTimerId = 0x4759;
constexpr UINT kControllerPollingIntervalMs = 50;
constexpr double kGamepadAxisDeadZone = 0.1;

bool OptionEnabled(const flutter::EncodableValue* arguments,
                   const char* option) {
  if (arguments == nullptr) return false;
  const auto* options = std::get_if<flutter::EncodableMap>(arguments);
  if (options == nullptr) return false;
  const auto value = options->find(flutter::EncodableValue(option));
  if (value == options->end()) return false;
  const auto* enabled = std::get_if<bool>(&value->second);
  return enabled != nullptr && *enabled;
}

class InputEventStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit InputEventStreamHandler(GamepadGlyphsPlugin* plugin)
      : plugin_(plugin) {}

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override {
    plugin_->SetInputEventSink(
        std::move(events), OptionEnabled(arguments, "detectMouse"),
        OptionEnabled(arguments, "detectTouch"));
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override {
    plugin_->ClearInputEventSink();
    return nullptr;
  }

 private:
  GamepadGlyphsPlugin* plugin_;
};

}  // namespace

bool UpdateControllerInputState(ControllerInputState* state,
                                const std::vector<int>& controls,
                                const std::vector<double>& axes,
                                double axis_dead_zone) {
  if (!state->initialized || state->controls.size() != controls.size() ||
      state->axes.size() != axes.size()) {
    state->initialized = true;
    state->controls = controls;
    state->axes = axes;
    return false;
  }

  bool active = false;
  for (size_t index = 0; index < controls.size(); ++index) {
    if (controls[index] != 0 && controls[index] != state->controls[index]) {
      active = true;
    }
  }
  state->controls = controls;

  for (size_t index = 0; index < axes.size(); ++index) {
    if (std::abs(axes[index] - state->axes[index]) > axis_dead_zone) {
      state->axes[index] = axes[index];
      active = true;
    }
  }
  return active;
}

// static
void GamepadGlyphsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "gamepad_glyphs",
          &flutter::StandardMethodCodec::GetInstance());

  auto input_event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "gamepad_glyphs/input_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<GamepadGlyphsPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  input_event_channel->SetStreamHandler(
      std::make_unique<InputEventStreamHandler>(plugin.get()));

  registrar->AddPlugin(std::move(plugin));
}

GamepadGlyphsPlugin::GamepadGlyphsPlugin()
    : registrar_(nullptr),
      window_proc_delegate_id_(0),
      input_window_(nullptr),
      input_devices_registered_(false),
      mouse_input_registered_(false),
      detect_mouse_(false),
      detect_touch_(false) {}

GamepadGlyphsPlugin::GamepadGlyphsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      window_proc_delegate_id_(0),
      input_window_(nullptr),
      input_devices_registered_(false),
      mouse_input_registered_(false),
      detect_mouse_(false),
      detect_touch_(false) {
  window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowMessage(hwnd, message, wparam, lparam);
      });

}

GamepadGlyphsPlugin::~GamepadGlyphsPlugin() {
  if (input_window_ != nullptr) {
    KillTimer(input_window_, kControllerPollingTimerId);
  }
  if (registrar_ != nullptr && window_proc_delegate_id_ != 0) {
    registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
  }
}

void GamepadGlyphsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else {
    result->NotImplemented();
  }
}

void GamepadGlyphsPlugin::SetInputEventSink(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink,
    bool detect_mouse, bool detect_touch) {
  input_event_sink_ = std::move(sink);
  detect_mouse_ = detect_mouse;
  detect_touch_ = detect_touch;
  RegisterInputDevices(input_window_);
}

void GamepadGlyphsPlugin::ClearInputEventSink() {
  input_event_sink_.reset();
  detect_mouse_ = false;
  detect_touch_ = false;
  controller_states_.clear();
}

void GamepadGlyphsPlugin::EmitInputEvent(unsigned long vendor_id,
                                         unsigned long product_id,
                                         const char* kind) {
  if (input_event_sink_ == nullptr) {
    return;
  }

  std::fprintf(stderr, "gamepad_glyphs event: %s %lu:%lu\n", kind, vendor_id,
               product_id);
  std::fflush(stderr);

  flutter::EncodableMap event;
  event[flutter::EncodableValue("vendorId")] =
      flutter::EncodableValue(static_cast<int64_t>(vendor_id));
  event[flutter::EncodableValue("productId")] =
      flutter::EncodableValue(static_cast<int64_t>(product_id));
  event[flutter::EncodableValue("kind")] = flutter::EncodableValue(kind);
  input_event_sink_->Success(flutter::EncodableValue(event));
}

void GamepadGlyphsPlugin::EmitInputEventForRawDevice(HANDLE device,
                                                      const char* kind) {
  UINT name_size = 0;
  if (device == nullptr ||
      GetRawInputDeviceInfo(device, RIDI_DEVICENAME, nullptr, &name_size) ==
          static_cast<UINT>(-1) ||
      name_size == 0) {
    return;
  }

  std::wstring name(name_size, L'\0');
  if (GetRawInputDeviceInfo(device, RIDI_DEVICENAME, name.data(),
                            &name_size) == static_cast<UINT>(-1)) {
    return;
  }

  const auto vendor_marker = name.find(L"VID_");
  const auto product_marker = name.find(L"PID_");
  if (vendor_marker == std::wstring::npos ||
      product_marker == std::wstring::npos) {
    return;
  }

  try {
    const auto vendor_id = std::stoul(name.substr(vendor_marker + 4, 4),
                                      nullptr, 16);
    const auto product_id = std::stoul(name.substr(product_marker + 4, 4),
                                       nullptr, 16);
    EmitInputEvent(vendor_id, product_id, kind);
  } catch (const std::exception&) {
  }
}

void GamepadGlyphsPlugin::EmitKeyboardEvent() {
  if (input_event_sink_ == nullptr) {
    return;
  }

  std::fprintf(stderr, "gamepad_glyphs event: keyboard\n");
  std::fflush(stderr);

  flutter::EncodableMap event;
  event[flutter::EncodableValue("vendorId")] = flutter::EncodableValue();
  event[flutter::EncodableValue("productId")] = flutter::EncodableValue();
  event[flutter::EncodableValue("kind")] =
      flutter::EncodableValue("keyboard");
  input_event_sink_->Success(flutter::EncodableValue(event));
}

std::optional<LRESULT> GamepadGlyphsPlugin::HandleWindowMessage(
    HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  // The implicit Flutter view may not exist yet when the plugin is
  // constructed. Register against the actual top-level window on its first
  // message instead of silently missing the keyboard registration.
  if (!input_devices_registered_ && hwnd != nullptr) {
    RegisterInputDevices(hwnd);
  }

  if (message == WM_TIMER && wparam == kControllerPollingTimerId) {
    PollGameControllers();
    return std::nullopt;
  }

  if (message == WM_POINTERDOWN && detect_touch_) {
    const auto pointer_id = GET_POINTERID_WPARAM(wparam);
    POINTER_INPUT_TYPE pointer_type = PT_POINTER;
    POINTER_INFO pointer_info = {};
    if (GetPointerType(pointer_id, &pointer_type) && pointer_type == PT_TOUCH &&
        GetPointerInfo(pointer_id, &pointer_info)) {
      EmitInputEventForRawDevice(pointer_info.sourceDevice, "touch");
    }
    return std::nullopt;
  }

  if (message != WM_INPUT) {
    return std::nullopt;
  }

  UINT size = 0;
  if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lparam), RID_INPUT, nullptr,
                      &size, sizeof(RAWINPUTHEADER)) == static_cast<UINT>(-1) ||
      size == 0) {
    return std::nullopt;
  }

  std::vector<BYTE> buffer(size);
  if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lparam), RID_INPUT,
                      buffer.data(), &size,
                      sizeof(RAWINPUTHEADER)) == static_cast<UINT>(-1)) {
    return std::nullopt;
  }

  const auto* raw_input = reinterpret_cast<const RAWINPUT*>(buffer.data());
  if (raw_input->header.dwType == RIM_TYPEKEYBOARD) {
    if ((raw_input->data.keyboard.Flags & RI_KEY_BREAK) == 0) {
      EmitKeyboardEvent();
    }
  } else if (raw_input->header.dwType == RIM_TYPEMOUSE && detect_mouse_) {
    EmitInputEventForRawDevice(raw_input->header.hDevice, "mouse");
  }
  return std::nullopt;
}

void GamepadGlyphsPlugin::RegisterInputDevices(HWND window) {
  if (window == nullptr) return;
  input_window_ = window;

  if (!input_devices_registered_) {
    // Raw Input is used only for keyboard key-down events. Controllers are
    // polled through Windows.Gaming.Input so changing HID motion, battery,
    // and status reports cannot masquerade as user input.
    RAWINPUTDEVICE keyboard = {0x01, 0x06, RIDEV_INPUTSINK, window};
    if (!RegisterRawInputDevices(&keyboard, 1, sizeof(keyboard))) {
      return;
    }
    input_devices_registered_ = true;
    SetTimer(input_window_, kControllerPollingTimerId,
             kControllerPollingIntervalMs, nullptr);
  }

  if (detect_mouse_ && !mouse_input_registered_) {
    RAWINPUTDEVICE mouse = {0x01, 0x02, RIDEV_INPUTSINK, window};
    if (RegisterRawInputDevices(&mouse, 1, sizeof(mouse))) {
      mouse_input_registered_ = true;
    }
  }
}

void GamepadGlyphsPlugin::PollGameControllers() {
  using namespace winrt::Windows::Gaming::Input;

  try {
    std::unordered_set<std::wstring> connected_controllers;
    bool emitted = false;
    for (const auto& raw_controller :
         RawGameController::RawGameControllers()) {
      const std::wstring controller_id(raw_controller.NonRoamableId());
      connected_controllers.insert(controller_id);

      std::vector<int> controls;
      std::vector<double> axes;

      const auto gamepad = Gamepad::FromGameController(raw_controller);
      if (gamepad != nullptr) {
        const auto reading = gamepad.GetCurrentReading();
        const auto buttons = static_cast<std::uint32_t>(reading.Buttons);
        for (std::uint32_t bit = 0; bit < 32; ++bit) {
          controls.push_back((buttons & (1u << bit)) == 0 ? 0 : 1);
        }
        axes = {
            reading.LeftTrigger,
            reading.RightTrigger,
            reading.LeftThumbstickX,
            reading.LeftThumbstickY,
            reading.RightThumbstickX,
            reading.RightThumbstickY,
        };
      } else {
        // This follows the original .NET InputPollingService: raw-only
        // controllers count pressed buttons and D-pad switches, but not raw
        // axes whose neutral values and semantics vary by controller.
        winrt::com_array<bool> buttons(raw_controller.ButtonCount());
        winrt::com_array<GameControllerSwitchPosition> switches(
            raw_controller.SwitchCount());
        winrt::com_array<double> raw_axes(raw_controller.AxisCount());
        raw_controller.GetCurrentReading(buttons, switches, raw_axes);

        for (bool pressed : buttons) controls.push_back(pressed ? 1 : 0);
        for (auto position : switches) {
          controls.push_back(
              position == GameControllerSwitchPosition::Center
                  ? 0
                  : static_cast<int>(position) + 1);
        }
      }

      const bool has_input = UpdateControllerInputState(
          &controller_states_[controller_id], controls, axes,
          kGamepadAxisDeadZone);
      if (has_input && !emitted) {
        EmitInputEvent(raw_controller.HardwareVendorId(),
                       raw_controller.HardwareProductId());
        emitted = true;
      }
    }
    for (auto it = controller_states_.begin(); it != controller_states_.end();) {
      if (connected_controllers.count(it->first) == 0) {
        it = controller_states_.erase(it);
      } else {
        ++it;
      }
    }
  } catch (const winrt::hresult_error&) {
    // A controller can disconnect between enumeration and reading. The next
    // polling tick will enumerate the current device list again.
  }
}

}  // namespace gamepad_glyphs
