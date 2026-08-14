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
#include <vector>

namespace gamepad_glyphs {

namespace {

constexpr UINT_PTR kControllerPollingTimerId = 0x4759;
constexpr UINT kControllerPollingIntervalMs = 50;
constexpr double kGamepadAxisDeadZone = 0.1;

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
      input_devices_registered_(false) {}

GamepadGlyphsPlugin::GamepadGlyphsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      window_proc_delegate_id_(0),
      input_window_(nullptr),
      input_devices_registered_(false) {
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

  std::fprintf(stderr, "gamepad_glyphs event: controller %lu:%lu\n",
               vendor_id, product_id);
  std::fflush(stderr);

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

  std::fprintf(stderr, "gamepad_glyphs event: keyboard\n");
  std::fflush(stderr);

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

  if (message == WM_TIMER && wparam == kControllerPollingTimerId) {
    PollGameControllers();
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
  }
  return std::nullopt;
}

void GamepadGlyphsPlugin::RegisterInputDevices(HWND window) {
  if (input_devices_registered_ || window == nullptr) {
    return;
  }

  // Raw Input is used only for keyboard key-down events. Controllers are
  // polled through Windows.Gaming.Input so changing HID motion, battery, and
  // status reports cannot masquerade as user input.
  RAWINPUTDEVICE devices[] = {{0x01, 0x06, RIDEV_INPUTSINK, window}};

  if (!RegisterRawInputDevices(devices, ARRAYSIZE(devices),
                               sizeof(RAWINPUTDEVICE))) {
    return;
  }

  input_window_ = window;
  input_devices_registered_ = true;
  SetTimer(input_window_, kControllerPollingTimerId,
           kControllerPollingIntervalMs, nullptr);
}

void GamepadGlyphsPlugin::PollGameControllers() {
  using namespace winrt::Windows::Gaming::Input;

  try {
    for (const auto& raw_controller :
         RawGameController::RawGameControllers()) {
      bool has_input = false;

      const auto gamepad = Gamepad::FromGameController(raw_controller);
      if (gamepad != nullptr) {
        const auto reading = gamepad.GetCurrentReading();
        has_input =
            reading.Buttons != GamepadButtons::None ||
            reading.LeftTrigger > kGamepadAxisDeadZone ||
            reading.RightTrigger > kGamepadAxisDeadZone ||
            std::abs(reading.LeftThumbstickX) > kGamepadAxisDeadZone ||
            std::abs(reading.LeftThumbstickY) > kGamepadAxisDeadZone ||
            std::abs(reading.RightThumbstickX) > kGamepadAxisDeadZone ||
            std::abs(reading.RightThumbstickY) > kGamepadAxisDeadZone;
      } else {
        // This follows the original .NET InputPollingService: raw-only
        // controllers count pressed buttons and D-pad switches, but not raw
        // axes whose neutral values and semantics vary by controller.
        winrt::com_array<bool> buttons(raw_controller.ButtonCount());
        winrt::com_array<GameControllerSwitchPosition> switches(
            raw_controller.SwitchCount());
        winrt::com_array<double> axes(raw_controller.AxisCount());
        raw_controller.GetCurrentReading(buttons, switches, axes);

        has_input =
            std::any_of(buttons.begin(), buttons.end(),
                        [](bool pressed) { return pressed; }) ||
            std::any_of(switches.begin(), switches.end(), [](auto position) {
              return position != GameControllerSwitchPosition::Center;
            });
      }

      if (has_input) {
        EmitInputEvent(raw_controller.HardwareVendorId(),
                       raw_controller.HardwareProductId());
        return;
      }
    }
  } catch (const winrt::hresult_error&) {
    // A controller can disconnect between enumeration and reading. The next
    // polling tick will enumerate the current device list again.
  }
}

}  // namespace gamepad_glyphs
