#include "include/gamepad_glyphs/gamepad_glyphs_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <algorithm>
#include <array>
#include <cerrno>
#include <cstdint>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <map>
#include <string>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <utility>
#include <unistd.h>

#include "gamepad_glyphs_plugin_private.h"

#define GAMEPAD_GLYPHS_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), gamepad_glyphs_plugin_get_type(), \
                              GamepadGlyphsPlugin))

enum class InputDeviceKind { kKeyboard, kController, kMouse, kTouch };

struct AxisState {
  bool available;
  int value;
  int dead_zone;
};

struct InputDevice {
  int fd;
  InputDeviceKind kind;
  unsigned short vendor_id;
  unsigned short product_id;
  std::array<AxisState, ABS_MAX + 1> axes;
};

struct _GamepadGlyphsPlugin {
  GObject parent_instance;
  FlEventChannel* input_event_channel;
  guint input_poll_source;
  guint input_scan_ticks;
  bool input_listening;
  bool detect_mouse;
  bool detect_touch;
  std::map<std::string, InputDevice>* input_devices;
};

G_DEFINE_TYPE(GamepadGlyphsPlugin, gamepad_glyphs_plugin, g_object_get_type())

static void close_input_devices(GamepadGlyphsPlugin* self) {
  if (self->input_devices == nullptr) return;
  for (const auto& entry : *self->input_devices) {
    close(entry.second.fd);
  }
  self->input_devices->clear();
}

// Called when a method call is received from Flutter.
static void gamepad_glyphs_plugin_handle_method_call(
    GamepadGlyphsPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

bool controller_axis_is_active(int baseline_value, int current_value,
                               int dead_zone) {
  const auto delta = static_cast<std::int64_t>(current_value) - baseline_value;
  const auto distance = delta < 0 ? -delta : delta;
  return distance > dead_zone;
}

static void gamepad_glyphs_plugin_dispose(GObject* object) {
  GamepadGlyphsPlugin* self = GAMEPAD_GLYPHS_PLUGIN(object);
  if (self->input_poll_source != 0) {
    g_source_remove(self->input_poll_source);
    self->input_poll_source = 0;
  }
  close_input_devices(self);
  g_clear_object(&self->input_event_channel);
  G_OBJECT_CLASS(gamepad_glyphs_plugin_parent_class)->dispose(object);
}

static void gamepad_glyphs_plugin_finalize(GObject* object) {
  GamepadGlyphsPlugin* self = GAMEPAD_GLYPHS_PLUGIN(object);
  delete self->input_devices;
  self->input_devices = nullptr;
  G_OBJECT_CLASS(gamepad_glyphs_plugin_parent_class)->finalize(object);
}

static void gamepad_glyphs_plugin_class_init(GamepadGlyphsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = gamepad_glyphs_plugin_dispose;
  G_OBJECT_CLASS(klass)->finalize = gamepad_glyphs_plugin_finalize;
}

static void gamepad_glyphs_plugin_init(GamepadGlyphsPlugin* self) {
  self->input_event_channel = nullptr;
  self->input_poll_source = 0;
  self->input_scan_ticks = 60;
  self->input_listening = false;
  self->detect_mouse = false;
  self->detect_touch = false;
  self->input_devices = new std::map<std::string, InputDevice>();
}

static bool has_bit(const unsigned long* bits, int bit) {
  return (bits[bit / (sizeof(unsigned long) * 8)] &
          (1UL << (bit % (sizeof(unsigned long) * 8)))) != 0;
}

static const gchar* input_kind_name(InputDeviceKind kind) {
  switch (kind) {
    case InputDeviceKind::kKeyboard:
      return "keyboard";
    case InputDeviceKind::kMouse:
      return "mouse";
    case InputDeviceKind::kTouch:
      return "touch";
    case InputDeviceKind::kController:
      return "gamepad";
  }
  return "gamepad";
}

static void emit_input_event(GamepadGlyphsPlugin* self,
                             const InputDevice& device) {
  if (self->input_event_channel == nullptr || !self->input_listening) return;

  g_autoptr(FlValue) event = fl_value_new_map();
  if (device.kind != InputDeviceKind::kController) {
    fl_value_set_string(event, "vendorId", fl_value_new_null());
    fl_value_set_string(event, "productId", fl_value_new_null());
  } else {
    fl_value_set_string(event, "vendorId",
                        fl_value_new_int(device.vendor_id));
    fl_value_set_string(event, "productId",
                        fl_value_new_int(device.product_id));
  }
  fl_value_set_string(event, "kind",
                      fl_value_new_string(input_kind_name(device.kind)));
  fl_event_channel_send(self->input_event_channel, event, nullptr, nullptr);
}

static gboolean key_press_event_cb(GtkWidget*, GdkEventKey*,
                                   gpointer user_data) {
  GamepadGlyphsPlugin* self = GAMEPAD_GLYPHS_PLUGIN(user_data);
  emit_input_event(
      self, InputDevice{-1, InputDeviceKind::kKeyboard, 0, 0});
  return GDK_EVENT_PROPAGATE;
}

static gboolean pointer_event_cb(GtkWidget*, GdkEvent* event,
                                 gpointer user_data) {
  GamepadGlyphsPlugin* self = GAMEPAD_GLYPHS_PLUGIN(user_data);
  GdkDevice* device = gdk_event_get_source_device(event);
  if (device == nullptr) device = gdk_event_get_device(event);
  if (device == nullptr) return GDK_EVENT_PROPAGATE;

  const GdkInputSource source = gdk_device_get_source(device);
  if (source == GDK_SOURCE_TOUCHSCREEN) {
    if (self->detect_touch) {
      emit_input_event(self, InputDevice{-1, InputDeviceKind::kTouch, 0, 0});
    }
  } else if (self->detect_mouse) {
    emit_input_event(self, InputDevice{-1, InputDeviceKind::kMouse, 0, 0});
  }
  return GDK_EVENT_PROPAGATE;
}

static bool is_possible_gamepad(const std::string& path) {
  struct stat device_stat = {};
  if (stat(path.c_str(), &device_stat) != 0) return true;

  char udev_path[64];
  snprintf(udev_path, sizeof(udev_path), "/run/udev/data/c%u:%u",
           major(device_stat.st_rdev), minor(device_stat.st_rdev));
  FILE* metadata = fopen(udev_path, "r");
  if (metadata == nullptr) return true;

  bool is_gamepad = false;
  char line[256];
  while (fgets(line, sizeof(line), metadata) != nullptr) {
    if (strncmp(line, "E:ID_INPUT_JOYSTICK=1", 21) == 0) {
      is_gamepad = true;
    }
  }
  fclose(metadata);
  return is_gamepad;
}

static bool read_device_input(GamepadGlyphsPlugin* self, InputDevice& device) {
  input_event events[32];
  bool has_input = false;
  while (true) {
    const ssize_t bytes = read(device.fd, events, sizeof(events));
    if (bytes <= 0) {
      if (bytes < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
      return false;
    }
    const size_t count = static_cast<size_t>(bytes) / sizeof(input_event);
    for (size_t i = 0; i < count; ++i) {
      const bool key_down =
          events[i].type == EV_KEY && events[i].value != 0;
      bool controller_axis_moved = false;
      if (device.kind == InputDeviceKind::kController &&
          events[i].type == EV_ABS && events[i].code <= ABS_MAX) {
        AxisState& axis = device.axes[events[i].code];
        if (axis.available) {
          controller_axis_moved = controller_axis_is_active(
              axis.value, events[i].value, axis.dead_zone);
          if (controller_axis_moved) axis.value = events[i].value;
        } else {
          // Unknown axes establish a baseline on their first report. Treating
          // that setup report as activity makes newly connected controllers
          // take over the glyphs without any user input.
          axis = AxisState{true, events[i].value, 0};
        }
      }
      const bool active =
          (device.kind == InputDeviceKind::kKeyboard && key_down) ||
          (device.kind == InputDeviceKind::kController &&
           (controller_axis_moved || key_down)) ||
          (device.kind == InputDeviceKind::kMouse &&
           (events[i].type == EV_REL || key_down)) ||
          (device.kind == InputDeviceKind::kTouch &&
           (events[i].type == EV_ABS || key_down));
      has_input = has_input || active;
    }
  }
  const bool mouse_enabled =
      device.kind != InputDeviceKind::kMouse || self->detect_mouse;
  const bool touch_enabled =
      device.kind != InputDeviceKind::kTouch || self->detect_touch;
  if (has_input && mouse_enabled && touch_enabled) emit_input_event(self, device);
  return true;
}

static gboolean poll_input_devices(gpointer user_data) {
  GamepadGlyphsPlugin* self = GAMEPAD_GLYPHS_PLUGIN(user_data);

  if (++self->input_scan_ticks >= 60) {
    self->input_scan_ticks = 0;
    DIR* directory = opendir("/dev/input");
    if (directory != nullptr) {
      while (dirent* entry = readdir(directory)) {
        const std::string name(entry->d_name);
        if (name.rfind("event", 0) != 0 ||
            self->input_devices->find(name) != self->input_devices->end()) {
          continue;
        }

        const std::string path = "/dev/input/" + name;
        if (!is_possible_gamepad(path)) continue;
        const int fd = open(path.c_str(), O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;

        unsigned long event_bits[(EV_MAX / (sizeof(unsigned long) * 8)) + 1] =
            {};
        unsigned long key_bits[(KEY_MAX / (sizeof(unsigned long) * 8)) + 1] =
            {};
        unsigned long rel_bits[(REL_MAX / (sizeof(unsigned long) * 8)) + 1] =
            {};
        unsigned long abs_bits[(ABS_MAX / (sizeof(unsigned long) * 8)) + 1] =
            {};
        ioctl(fd, EVIOCGBIT(0, sizeof(event_bits)), event_bits);
        ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(key_bits)), key_bits);
        ioctl(fd, EVIOCGBIT(EV_REL, sizeof(rel_bits)), rel_bits);
        ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(abs_bits)), abs_bits);

        const bool has_keys = has_bit(event_bits, EV_KEY);
        const bool has_axes = has_bit(event_bits, EV_ABS);
        const bool has_relative_axes = has_bit(event_bits, EV_REL);
        const bool has_keyboard_keys = has_bit(key_bits, KEY_A) &&
                                       has_bit(key_bits, KEY_Z) &&
                                       has_bit(key_bits, KEY_ENTER);
        const bool has_gamepad_buttons = has_bit(key_bits, BTN_GAMEPAD) ||
                                         has_bit(key_bits, BTN_JOYSTICK);
        const bool has_mouse_buttons = has_bit(key_bits, BTN_MOUSE);
        const bool has_mouse_axes = has_bit(rel_bits, REL_X) &&
                                    has_bit(rel_bits, REL_Y);
        const bool has_touch = has_bit(key_bits, BTN_TOUCH) ||
                               has_bit(abs_bits, ABS_MT_POSITION_X) ||
                               has_bit(abs_bits, ABS_MT_POSITION_Y);
        if ((!has_keys && !has_axes && !has_relative_axes) ||
            (!has_axes && !has_keyboard_keys && !has_gamepad_buttons &&
             !has_mouse_buttons && !has_mouse_axes && !has_touch)) {
          close(fd);
          continue;
        }

        const InputDeviceKind kind = has_keyboard_keys
            ? InputDeviceKind::kKeyboard
            : has_gamepad_buttons ? InputDeviceKind::kController
            : (has_mouse_buttons || has_mouse_axes) ? InputDeviceKind::kMouse
            : has_touch ? InputDeviceKind::kTouch
            : InputDeviceKind::kController;

        input_id id = {};
        ioctl(fd, EVIOCGID, &id);
        InputDevice device{fd, kind, id.vendor, id.product, {}};
        if (kind == InputDeviceKind::kController) {
          for (int axis_code = 0; axis_code <= ABS_MAX; ++axis_code) {
            if (!has_bit(abs_bits, axis_code)) continue;
            input_absinfo axis_info = {};
            if (ioctl(fd, EVIOCGABS(axis_code), &axis_info) != 0) continue;
            const auto travel =
                std::max(
                    std::abs(static_cast<std::int64_t>(axis_info.maximum) -
                             axis_info.value),
                    std::abs(static_cast<std::int64_t>(axis_info.value) -
                             axis_info.minimum));
            device.axes[axis_code] = AxisState{
                true,
                axis_info.value,
                std::max(axis_info.flat, static_cast<int>(travel / 10)),
            };
          }
        }
        self->input_devices->emplace(name, std::move(device));
      }
      closedir(directory);
    }
  }

  for (auto it = self->input_devices->begin();
       it != self->input_devices->end();) {
    if (!read_device_input(self, it->second)) {
      close(it->second.fd);
      it = self->input_devices->erase(it);
    } else {
      ++it;
    }
  }
  return G_SOURCE_CONTINUE;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  GamepadGlyphsPlugin* plugin = GAMEPAD_GLYPHS_PLUGIN(user_data);
  gamepad_glyphs_plugin_handle_method_call(plugin, method_call);
}

static bool option_enabled(FlValue* arguments, const gchar* name) {
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return false;
  }
  FlValue* value = fl_value_lookup_string(arguments, name);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
         fl_value_get_bool(value);
}

static FlMethodErrorResponse* input_event_listen_cb(
    FlEventChannel* channel, FlValue* arguments, gpointer user_data) {
  GamepadGlyphsPlugin* plugin = GAMEPAD_GLYPHS_PLUGIN(user_data);
  plugin->detect_mouse = option_enabled(arguments, "detectMouse");
  plugin->detect_touch = option_enabled(arguments, "detectTouch");
  plugin->input_listening = true;
  if (plugin->input_poll_source == 0) {
    plugin->input_poll_source = g_timeout_add(16, poll_input_devices, plugin);
  }
  return nullptr;
}

static FlMethodErrorResponse* input_event_cancel_cb(
    FlEventChannel* channel, FlValue* arguments, gpointer user_data) {
  GamepadGlyphsPlugin* plugin = GAMEPAD_GLYPHS_PLUGIN(user_data);
  plugin->input_listening = false;
  plugin->detect_mouse = false;
  plugin->detect_touch = false;
  plugin->input_scan_ticks = 60;
  if (plugin->input_poll_source != 0) {
    g_source_remove(plugin->input_poll_source);
    plugin->input_poll_source = 0;
  }
  close_input_devices(plugin);
  return nullptr;
}

void gamepad_glyphs_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  GamepadGlyphsPlugin* plugin = GAMEPAD_GLYPHS_PLUGIN(
      g_object_new(gamepad_glyphs_plugin_get_type(), nullptr));

  FlView* view = fl_plugin_registrar_get_view(registrar);
  if (view != nullptr) {
    gtk_widget_add_events(GTK_WIDGET(view),
                          GDK_KEY_PRESS_MASK | GDK_BUTTON_PRESS_MASK |
                              GDK_POINTER_MOTION_MASK | GDK_TOUCH_MASK);
    g_signal_connect_object(view, "key-press-event",
                            G_CALLBACK(key_press_event_cb), plugin,
                            G_CONNECT_DEFAULT);
    g_signal_connect_object(view, "button-press-event",
                            G_CALLBACK(pointer_event_cb), plugin,
                            G_CONNECT_DEFAULT);
    g_signal_connect_object(view, "motion-notify-event",
                            G_CALLBACK(pointer_event_cb), plugin,
                            G_CONNECT_DEFAULT);
    g_signal_connect_object(view, "touch-event", G_CALLBACK(pointer_event_cb),
                            plugin, G_CONNECT_DEFAULT);
  }

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "gamepad_glyphs",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_autoptr(FlStandardMethodCodec) event_codec = fl_standard_method_codec_new();
  plugin->input_event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "gamepad_glyphs/input_events", FL_METHOD_CODEC(event_codec));
  fl_event_channel_set_stream_handlers(
      plugin->input_event_channel, input_event_listen_cb,
      input_event_cancel_cb, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
