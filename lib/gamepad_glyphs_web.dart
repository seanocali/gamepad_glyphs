import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'gamepad_glyphs_platform_interface.dart';
import 'src/controller_activity.dart';
import 'src/input_types.dart';

/// A web implementation of the GamepadGlyphsPlatform of the GamepadGlyphs plugin.
class GamepadGlyphsWeb extends GamepadGlyphsPlatform {
  /// Constructs a GamepadGlyphsWeb
  GamepadGlyphsWeb();

  static void registerWith(Registrar registrar) {
    GamepadGlyphsPlatform.instance = GamepadGlyphsWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Stream<InputDeviceEvent> inputEvents({
    bool detectMouse = false,
    bool detectTouch = false,
  }) {
    late final StreamController<InputDeviceEvent> controller;
    late final web.EventListener keyListener;
    late final web.EventListener pointerListener;
    late final web.FrameRequestCallback frameCallback;
    final gamepadStates = <int, ControllerActivityTracker>{};
    int? animationFrame;

    void emit(InputDeviceKind kind, {int? vendorId, int? productId}) {
      if (!controller.isClosed) {
        controller.add(
          InputDeviceEvent(
            vendorId: vendorId,
            productId: productId,
            kind: kind,
          ),
        );
      }
    }

    void pollGamepads(double _) {
      if (!controller.hasListener) return;

      final connectedIndices = <int>{};
      for (final gamepad in web.window.navigator.getGamepads().toDart) {
        if (gamepad == null || !gamepad.connected) continue;
        connectedIndices.add(gamepad.index);

        final buttons = gamepad.buttons.toDart;
        final axes = gamepad.axes.toDart;
        final state = gamepadStates.putIfAbsent(
          gamepad.index,
          ControllerActivityTracker.new,
        );
        if (state.update(
          buttonValues: buttons
              .map((button) => button.pressed ? 1.0 : button.value)
              .toList(),
          axisValues: axes.map((axis) => axis.toDartDouble).toList(),
        )) {
          final ids = _hardwareIdsFromGamepadId(gamepad.id);
          emit(
            InputDeviceKind.gamepad,
            vendorId: ids.vendorId,
            productId: ids.productId,
          );
        }
      }
      gamepadStates.removeWhere(
        (index, _) => !connectedIndices.contains(index),
      );
      animationFrame = web.window.requestAnimationFrame(frameCallback);
    }

    keyListener = ((web.Event _) {
      emit(InputDeviceKind.keyboard);
    }).toJS;
    pointerListener = ((web.Event rawEvent) {
      final event = rawEvent as web.PointerEvent;
      if (event.pointerType == 'mouse' && detectMouse) {
        emit(InputDeviceKind.mouse);
      } else if (event.pointerType == 'touch' &&
          detectTouch &&
          event.type == 'pointerdown') {
        emit(InputDeviceKind.touch);
      }
    }).toJS;
    frameCallback = pollGamepads.toJS;

    void start() {
      web.window.addEventListener('keydown', keyListener);
      if (detectMouse || detectTouch) {
        web.window.addEventListener('pointerdown', pointerListener);
        if (detectMouse) {
          web.window.addEventListener('pointermove', pointerListener);
        }
      }
      animationFrame = web.window.requestAnimationFrame(frameCallback);
    }

    void stop() {
      web.window.removeEventListener('keydown', keyListener);
      web.window.removeEventListener('pointerdown', pointerListener);
      web.window.removeEventListener('pointermove', pointerListener);
      final frame = animationFrame;
      if (frame != null) web.window.cancelAnimationFrame(frame);
      animationFrame = null;
      gamepadStates.clear();
    }

    controller = StreamController<InputDeviceEvent>.broadcast(
      onListen: start,
      onCancel: stop,
    );
    return controller.stream;
  }
}

({int? vendorId, int? productId}) _hardwareIdsFromGamepadId(String id) {
  final patterns = <RegExp>[
    RegExp(
      r'vendor:\s*([0-9a-f]{3,4}).*product:\s*([0-9a-f]{3,4})',
      caseSensitive: false,
    ),
    RegExp(r'^([0-9a-f]{3,4})-([0-9a-f]{3,4})-', caseSensitive: false),
    RegExp(
      r'vid[_:= -]([0-9a-f]{3,4}).*pid[_:= -]([0-9a-f]{3,4})',
      caseSensitive: false,
    ),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(id);
    if (match != null) {
      return (
        vendorId: int.tryParse(match.group(1)!, radix: 16),
        productId: int.tryParse(match.group(2)!, radix: 16),
      );
    }
  }
  return (vendorId: null, productId: null);
}
