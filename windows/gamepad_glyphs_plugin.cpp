#include "gamepad_glyphs_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <Xinput.h>

#include <VersionHelpers.h>

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <cstdlib>
#include <memory>
#include <optional>
#include <sstream>
#include <vector>

namespace gamepad_glyphs {

namespace {

constexpr UINT_PTR kXInputTimerId = 0x4759;
constexpr UINT kXInputTimerIntervalMs = 50;

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
    plugin_->SetInputEventSink(std::move(events));
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
      xinput_packet_numbers_{} {}

GamepadGlyphsPlugin::GamepadGlyphsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      window_proc_delegate_id_(0),
      input_window_(nullptr),
      input_devices_registered_(false),
      xinput_packet_numbers_{} {
  window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowMessage(hwnd, message, wparam, lparam);
      });

}

GamepadGlyphsPlugin::~GamepadGlyphsPlugin() {
  if (input_window_ != nullptr) {
    KillTimer(input_window_, kXInputTimerId);
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
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
  input_event_sink_ = std::move(sink);
}

void GamepadGlyphsPlugin::ClearInputEventSink() {
  input_event_sink_.reset();
}

void GamepadGlyphsPlugin::EmitInputEvent(unsigned long vendor_id,
                                         unsigned long product_id) {
  if (input_event_sink_ == nullptr) {
    return;
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("vendorId")] =
      flutter::EncodableValue(static_cast<int64_t>(vendor_id));
  event[flutter::EncodableValue("productId")] =
      flutter::EncodableValue(static_cast<int64_t>(product_id));
  input_event_sink_->Success(flutter::EncodableValue(event));
}

void GamepadGlyphsPlugin::EmitKeyboardEvent() {
  if (input_event_sink_ == nullptr) {
    return;
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("vendorId")] = flutter::EncodableValue();
  event[flutter::EncodableValue("productId")] = flutter::EncodableValue();
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

  if (message == WM_TIMER && wparam == kXInputTimerId) {
    PollXInput();
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
    return std::nullopt;
  }

  if (raw_input->header.dwType != RIM_TYPEHID) {
    return std::nullopt;
  }

  RID_DEVICE_INFO device_info{};
  device_info.cbSize = sizeof(device_info);
  UINT device_info_size = sizeof(device_info);
  if (GetRawInputDeviceInfo(raw_input->header.hDevice, RIDI_DEVICEINFO,
                            &device_info, &device_info_size) ==
          static_cast<UINT>(-1) ||
      device_info.dwType != RIM_TYPEHID) {
    return std::nullopt;
  }

  EmitInputEvent(device_info.hid.dwVendorId, device_info.hid.dwProductId);
  return std::nullopt;
}

void GamepadGlyphsPlugin::RegisterInputDevices(HWND window) {
  if (input_devices_registered_ || window == nullptr) {
    return;
  }

  RAWINPUTDEVICE devices[] = {
      // Keyboard.
      {0x01, 0x06, RIDEV_INPUTSINK, window},
      // Joystick and gamepad HID devices.
      {0x01, 0x04, RIDEV_INPUTSINK, window},
      {0x01, 0x05, RIDEV_INPUTSINK, window},
  };

  if (!RegisterRawInputDevices(devices, ARRAYSIZE(devices),
                               sizeof(RAWINPUTDEVICE))) {
    return;
  }

  input_window_ = window;
  input_devices_registered_ = true;
  SetTimer(input_window_, kXInputTimerId, kXInputTimerIntervalMs, nullptr);
}

void GamepadGlyphsPlugin::PollXInput() {
  for (DWORD index = 0; index < XUSER_MAX_COUNT; ++index) {
    XINPUT_STATE state{};
    const DWORD result = XInputGetState(index, &state);
    if (result != ERROR_SUCCESS) {
      xinput_packet_numbers_[index] = 0;
      continue;
    }

    if (state.dwPacketNumber == xinput_packet_numbers_[index]) {
      continue;
    }
    xinput_packet_numbers_[index] = state.dwPacketNumber;

    const auto& gamepad = state.Gamepad;
    const bool has_button_input = gamepad.wButtons != 0;
    const bool has_trigger_input =
        gamepad.bLeftTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD ||
        gamepad.bRightTrigger > XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
    const bool has_left_stick_input =
        std::abs(gamepad.sThumbLX) > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE ||
        std::abs(gamepad.sThumbLY) > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE;
    const bool has_right_stick_input =
        std::abs(gamepad.sThumbRX) > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE ||
        std::abs(gamepad.sThumbRY) > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE;

    if (has_button_input || has_trigger_input || has_left_stick_input ||
        has_right_stick_input) {
      // XInput does not expose the physical USB IDs. XInput devices are Xbox
      // controllers, so use the Xbox One profile as the safe glyph family.
      EmitInputEvent(1118, 721);
    }
  }
}

}  // namespace gamepad_glyphs
