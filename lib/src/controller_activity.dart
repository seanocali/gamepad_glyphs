/// Tracks controller samples without treating the first sample as activity.
///
/// Browser gamepads are polled, so a newly connected controller's initial
/// state can include setup values or the button used to connect it. This
/// tracker establishes that state as a baseline and reports only later input.
class ControllerActivityTracker {
  ControllerActivityTracker({this.axisDeadZone = 0.1});

  final double axisDeadZone;

  List<double>? _buttonValues;
  List<double>? _axisValues;

  bool update({
    required List<double> buttonValues,
    required List<double> axisValues,
  }) {
    final previousButtons = _buttonValues;
    final previousAxes = _axisValues;
    if (previousButtons == null ||
        previousAxes == null ||
        previousButtons.length != buttonValues.length ||
        previousAxes.length != axisValues.length) {
      _buttonValues = List<double>.of(buttonValues);
      _axisValues = List<double>.of(axisValues);
      return false;
    }

    var active = false;
    for (var index = 0; index < buttonValues.length; index++) {
      final current = buttonValues[index];
      if (current <= axisDeadZone) {
        // Releases do not claim the active-input device, but they reset the
        // baseline so the next press does.
        previousButtons[index] = current;
      } else if ((current - previousButtons[index]).abs() > axisDeadZone) {
        previousButtons[index] = current;
        active = true;
      }
    }

    for (var index = 0; index < axisValues.length; index++) {
      final current = axisValues[index];
      if ((current - previousAxes[index]).abs() > axisDeadZone) {
        previousAxes[index] = current;
        active = true;
      }
    }
    return active;
  }
}
