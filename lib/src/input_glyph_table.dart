import 'input_types.dart';

/// The glyph names used for one semantic input across supported devices.
class InputGlyphRow {
  const InputGlyphRow({
    required this.assetName,
    this.monochromeIndex,
    this.keyboard,
    this.xbox360,
    this.xboxOne,
    this.xboxSeriesXs,
    this.ps3,
    this.ps4,
    this.ps5,
    this.wii,
    this.switchJoyCon,
    this.steamG1,
  });

  /// The default asset name, also used by uncustomized controller families.
  final String assetName;

  /// The source-font index used by the generated monochrome glyph assets.
  final int? monochromeIndex;
  final String? keyboard;
  final String? xbox360;
  final String? xboxOne;
  final String? xboxSeriesXs;
  final String? ps3;
  final String? ps4;
  final String? ps5;
  final String? wii;
  final String? switchJoyCon;
  final String? steamG1;

  String? glyphName(GamepadDevice type) {
    switch (type) {
      case GamepadDevice.keyboard:
        return _validName(keyboard);
      case GamepadDevice.xbox360:
        return _validName(xbox360 ?? assetName);
      case GamepadDevice.xboxOne:
        return _validName(xboxOne ?? assetName);
      case GamepadDevice.xboxSeriesXs:
        return _validName(xboxSeriesXs ?? xboxOne ?? assetName);
      case GamepadDevice.ps3:
        return _validName(ps3 ?? assetName);
      case GamepadDevice.ps4:
        return _validName(ps4 ?? assetName);
      case GamepadDevice.ps5:
        return _validName(ps5 ?? assetName);
      case GamepadDevice.switchJoyCon:
        return _validName(switchJoyCon ?? assetName);
      case GamepadDevice.wii:
        return _validName(wii ?? assetName);
      case GamepadDevice.steamG1:
        return _validName(steamG1);
    }
  }

  static String? _validName(String? name) =>
      name == null || name.isEmpty ? null : name;

  InputGlyphRow copyWith({
    String? assetName,
    int? monochromeIndex,
    String? keyboard,
    String? xbox360,
    String? xboxOne,
    String? xboxSeriesXs,
    String? ps3,
    String? ps4,
    String? ps5,
    String? wii,
    String? switchJoyCon,
    String? steamG1,
  }) {
    return InputGlyphRow(
      assetName: assetName ?? this.assetName,
      monochromeIndex: monochromeIndex ?? this.monochromeIndex,
      keyboard: keyboard ?? this.keyboard,
      xbox360: xbox360 ?? this.xbox360,
      xboxOne: xboxOne ?? this.xboxOne,
      xboxSeriesXs: xboxSeriesXs ?? this.xboxSeriesXs,
      ps3: ps3 ?? this.ps3,
      ps4: ps4 ?? this.ps4,
      ps5: ps5 ?? this.ps5,
      wii: wii ?? this.wii,
      switchJoyCon: switchJoyCon ?? this.switchJoyCon,
      steamG1: steamG1 ?? this.steamG1,
    );
  }
}

/// Centralized, customizable mapping from semantic inputs to glyph names.
class InputGlyphTable {
  const InputGlyphTable({required this.rows});

  final Map<GamepadInputType, InputGlyphRow> rows;

  String? glyphName(GamepadInputType input, GamepadDevice device) {
    return rows[input]?.glyphName(device);
  }

  int monochromeIndex(GamepadInputType input) {
    return rows[input]?.monochromeIndex ?? input.index;
  }

  /// Returns a table with only the selected keyboard mappings changed.
  InputGlyphTable withKeyboardOverrides(
    Map<GamepadInputType, String> overrides,
  ) {
    final updated = <GamepadInputType, InputGlyphRow>{...rows};
    for (final entry in overrides.entries) {
      final row = updated[entry.key];
      if (row != null) {
        updated[entry.key] = row.copyWith(keyboard: entry.value);
      }
    }
    return InputGlyphTable(rows: Map.unmodifiable(updated));
  }
}

/// The package's default mapping. Applications can derive a customized table
/// with [InputGlyphTable.withKeyboardOverrides] and pass it to [GamepadGlyph].
const defaultInputGlyphs = InputGlyphTable(
  rows: <GamepadInputType, InputGlyphRow>{
    GamepadInputType.north: InputGlyphRow(
      assetName: 'Y',
      monochromeIndex: 3,
      keyboard: 'X',
      steamG1: 'Y',
      ps3: 'Triangle',
      ps4: 'Triangle',
      ps5: 'Triangle',
    ),
    GamepadInputType.south: InputGlyphRow(
      assetName: 'A',
      monochromeIndex: 0,
      keyboard: 'Space',
      steamG1: 'A',
      ps3: 'Cross',
      ps4: 'Cross',
      ps5: 'Cross',
    ),
    GamepadInputType.east: InputGlyphRow(
      assetName: 'B',
      monochromeIndex: 1,
      keyboard: 'C',
      steamG1: 'B',
      ps3: 'Circle',
      ps4: 'Circle',
      ps5: 'Circle',
    ),
    GamepadInputType.west: InputGlyphRow(
      assetName: 'X',
      monochromeIndex: 2,
      keyboard: 'R',
      steamG1: 'X',
      ps3: 'Square',
      ps4: 'Square',
      ps5: 'Square',
    ),
    GamepadInputType.view: InputGlyphRow(
      assetName: 'View',
      keyboard: 'RightShift',
      xbox360: 'Back',
      ps3: 'Select',
      ps4: 'Share',
      ps5: 'Create',
      switchJoyCon: 'Minus',
      steamG1: 'Select',
    ),
    GamepadInputType.menu: InputGlyphRow(
      assetName: 'Menu',
      keyboard: 'Enter',
      xbox360: 'Start',
      ps3: 'Start',
      ps4: 'Options',
      ps5: 'Options',
      switchJoyCon: 'Plus',
      steamG1: 'Start',
    ),
    GamepadInputType.leftShoulder: InputGlyphRow(
      assetName: 'LeftShoulder',
      keyboard: 'Q',
      ps3: 'L1',
      ps4: 'L1',
      ps5: 'L1',
      switchJoyCon: 'L',
      steamG1: 'LB',
    ),
    GamepadInputType.rightShoulder: InputGlyphRow(
      assetName: 'RightShoulder',
      keyboard: 'G',
      ps3: 'R1',
      ps4: 'R1',
      ps5: 'R1',
      switchJoyCon: 'R',
      steamG1: 'RB',
    ),
    GamepadInputType.leftRightShoulder: InputGlyphRow(
      assetName: 'LeftRightShoulder',
      keyboard: 'ChevronLeftRight',
      ps3: 'L1R1',
      ps4: 'L1R1',
      ps5: 'L1R1',
      switchJoyCon: 'LR',
      steamG1: 'LeftRightShoulder',
    ),
    GamepadInputType.leftTrigger: InputGlyphRow(
      assetName: 'LeftTrigger',
      keyboard: 'Divide',
      ps3: 'L2',
      ps4: 'L2',
      ps5: 'L2',
      switchJoyCon: 'ZL',
      steamG1: 'LT',
    ),
    GamepadInputType.rightTrigger: InputGlyphRow(
      assetName: 'RightTrigger',
      keyboard: 'Enter',
      ps3: 'R2',
      ps4: 'R2',
      ps5: 'R2',
      switchJoyCon: 'ZR',
      steamG1: 'RT',
    ),
    GamepadInputType.leftRightTrigger: InputGlyphRow(
      assetName: 'LeftRightTrigger',
      keyboard: 'BracketLeftRight',
      ps3: 'L2R2',
      ps4: 'L2R2',
      ps5: 'L2R2',
      switchJoyCon: 'ZLZR',
      steamG1: 'LeftRightTrigger',
    ),
    GamepadInputType.dPad: InputGlyphRow(
      assetName: 'DPad',
      keyboard: 'UpDownLeftRight',
      switchJoyCon: 'DPad',
      steamG1: 'DPad',
    ),
    GamepadInputType.dPadUp: InputGlyphRow(
      assetName: 'DPadUp',
      keyboard: 'Up',
      switchJoyCon: 'DPadUp',
      steamG1: 'DPadUp',
    ),
    GamepadInputType.dPadDown: InputGlyphRow(
      assetName: 'DPadDown',
      keyboard: 'Down',
      switchJoyCon: 'DPadDown',
      steamG1: 'DPadDown',
    ),
    GamepadInputType.dPadLeft: InputGlyphRow(
      assetName: 'DPadLeft',
      keyboard: 'Left',
      switchJoyCon: 'DPadLeft',
      steamG1: 'DPadLeft',
    ),
    GamepadInputType.dPadRight: InputGlyphRow(
      assetName: 'DPadRight',
      keyboard: 'Right',
      switchJoyCon: 'DPadRight',
      steamG1: 'DPadRight',
    ),
    GamepadInputType.dPadUpLeft: InputGlyphRow(
      assetName: 'DPadUpLeft',
      keyboard: 'UpLeft',
      xboxSeriesXs: 'DPadLeftUp',
      switchJoyCon: 'DPadUpLeft',
      steamG1: 'DPadUpLeft',
    ),
    GamepadInputType.dPadDownRight: InputGlyphRow(
      assetName: 'DPadDownRight',
      keyboard: 'DownRight',
      switchJoyCon: 'DPadDownRight',
      steamG1: 'DPadDownRight',
    ),
    GamepadInputType.dPadDownLeft: InputGlyphRow(
      assetName: 'DPadDownLeft',
      keyboard: 'DownLeft',
      switchJoyCon: 'DPadDownLeft',
      steamG1: 'DPadDownLeft',
    ),
    GamepadInputType.dPadUpRight: InputGlyphRow(
      assetName: 'DPadUpRight',
      keyboard: 'UpRight',
      xboxSeriesXs: 'DPadUpRight',
      switchJoyCon: 'DPadUpRight',
      steamG1: 'DPadUpRight',
    ),
    GamepadInputType.dPadUpDown: InputGlyphRow(
      assetName: 'DPadUpDown',
      keyboard: 'UpDown',
      switchJoyCon: 'DPadUpDown',
      steamG1: 'DPadUpDown',
    ),
    GamepadInputType.dPadLeftRight: InputGlyphRow(
      assetName: 'DPadLeftRight',
      keyboard: 'LeftRight',
      switchJoyCon: 'DPadLeftRight',
      steamG1: 'DPadLeftRight',
    ),
    GamepadInputType.leftThumbstick: InputGlyphRow(
      assetName: 'LeftThumbstick',
      keyboard: 'WSAD',
      steamG1: 'LeftThumbstick',
    ),
    GamepadInputType.leftThumbstickClockwise: InputGlyphRow(
      assetName: 'LeftThumbstickClockwise',
      keyboard: 'R',
      steamG1: 'LeftThumbstickRotationClockwise',
    ),
    GamepadInputType.leftThumbstickCounterclockwise: InputGlyphRow(
      assetName: 'LeftThumbstickCounterclockwise',
      keyboard: 'Q',
      steamG1: 'LeftThumbstickRotationCounterclockwise',
    ),
    GamepadInputType.leftThumbstickUp: InputGlyphRow(
      assetName: 'LeftThumbstickUp',
      keyboard: 'W',
      steamG1: 'LeftThumbstickUp',
    ),
    GamepadInputType.leftThumbstickDown: InputGlyphRow(
      assetName: 'LeftThumbstickDown',
      keyboard: 'S',
      steamG1: 'LeftThumbstickDown',
    ),
    GamepadInputType.leftThumbstickLeft: InputGlyphRow(
      assetName: 'LeftThumbstickLeft',
      keyboard: 'A',
      steamG1: 'LeftThumbstickLeft',
    ),
    GamepadInputType.leftThumbstickRight: InputGlyphRow(
      assetName: 'LeftThumbstickRight',
      keyboard: 'D',
      steamG1: 'LeftThumbstickRight',
    ),
    GamepadInputType.leftThumbstickUpLeft: InputGlyphRow(
      assetName: 'LeftThumbstickUpLeft',
      keyboard: 'WA',
      ps3: 'LeftThumbstickUpLeft',
      ps4: 'LeftThumbstickUpLeft',
      ps5: 'LeftThumbstickUpLeft',
      steamG1: 'LeftThumbstickUpLeft',
    ),
    GamepadInputType.leftThumbstickDownRight: InputGlyphRow(
      assetName: 'LeftThumbstickDownRight',
      keyboard: 'SD',
      ps3: 'LeftThumbstickDownRight',
      ps4: 'LeftThumbstickDownRight',
      ps5: 'LeftThumbstickDownRight',
      steamG1: 'LeftThumbstickDownRight',
    ),
    GamepadInputType.leftThumbstickDownLeft: InputGlyphRow(
      assetName: 'LeftThumbstickDownLeft',
      keyboard: 'SA',
      ps3: 'LeftThumbstickDownLeft',
      ps4: 'LeftThumbstickDownLeft',
      ps5: 'LeftThumbstickDownLeft',
      steamG1: 'LeftThumbstickLeftDown',
    ),
    GamepadInputType.leftThumbstickUpRight: InputGlyphRow(
      assetName: 'LeftThumbstickUpRight',
      keyboard: 'WD',
      ps3: 'LeftThumbstickUpRight',
      ps4: 'LeftThumbstickUpRight',
      ps5: 'LeftThumbstickUpRight',
      steamG1: 'LeftThumbstickUpRight',
    ),
    GamepadInputType.leftThumbstickLeftRight: InputGlyphRow(
      assetName: 'LeftThumbstickLeftRight',
      keyboard: 'AD',
      steamG1: 'LeftThumbstickLeftRight',
    ),
    GamepadInputType.leftThumbstickUpDown: InputGlyphRow(
      assetName: 'LeftThumbstickUpDown',
      keyboard: 'WS',
      steamG1: 'LeftThumbstickUpDown',
    ),
    GamepadInputType.leftThumbstickButton: InputGlyphRow(
      assetName: 'LeftThumbstickButton',
      keyboard: 'Shift',
      ps3: 'L3',
      ps4: 'L3',
      ps5: 'L3',
      switchJoyCon: 'LeftThumbStickButton',
      steamG1: 'LeftThumbstickClick',
    ),
    GamepadInputType.rightThumbstick: InputGlyphRow(
      assetName: 'RightThumbstick',
      keyboard: '8246',
      switchJoyCon: 'RightThumbStick',
      steamG1: 'Trackpad',
    ),
    GamepadInputType.rightThumbstickClockwise: InputGlyphRow(
      assetName: 'RightThumbstickClockwise',
      keyboard: '9',
      steamG1: 'TrackpadClockwise',
    ),
    GamepadInputType.rightThumbstickCounterclockwise: InputGlyphRow(
      assetName: 'RightThumbstickCounterclockwise',
      keyboard: '7',
      steamG1: 'TrackpadCounterClockwise',
    ),
    GamepadInputType.rightThumbstickUp: InputGlyphRow(
      assetName: 'RightThumbstickUp',
      keyboard: '8',
      steamG1: 'TrackpadUp',
    ),
    GamepadInputType.rightThumbstickDown: InputGlyphRow(
      assetName: 'RightThumbstickDown',
      keyboard: '2',
      steamG1: 'TrackpadDown',
    ),
    GamepadInputType.rightThumbstickLeft: InputGlyphRow(
      assetName: 'RightThumbstickLeft',
      keyboard: '4',
      steamG1: 'TrackpadLeft',
    ),
    GamepadInputType.rightThumbstickRight: InputGlyphRow(
      assetName: 'RightThumbstickRight',
      keyboard: '6',
      steamG1: 'TrackpadRight',
    ),
    GamepadInputType.rightThumbstickUpLeft: InputGlyphRow(
      assetName: 'RightThumbstickUpLeft',
      keyboard: '84',
      ps3: 'RightThumbstickUpLeft',
      ps4: 'RightThumbstickUpLeft',
      ps5: 'RightThumbstickUpLeft',
      steamG1: 'TrackpadUpLeft',
    ),
    GamepadInputType.rightThumbstickDownRight: InputGlyphRow(
      assetName: 'RightThumbstickDownRight',
      keyboard: '62',
      ps3: 'RightThumbstickDownRight',
      ps4: 'RightThumbstickDownRight',
      ps5: 'RightThumbstickDownRight',
      steamG1: 'TrackpadDownRight',
    ),
    GamepadInputType.rightThumbstickDownLeft: InputGlyphRow(
      assetName: 'RightThumbstickDownLeft',
      keyboard: '42',
      ps3: 'RightThumbstickDownLeft',
      ps4: 'RightThumbstickDownLeft',
      ps5: 'RightThumbstickDownLeft',
      steamG1: 'TrackpadDownLeft',
    ),
    GamepadInputType.rightThumbstickUpRight: InputGlyphRow(
      assetName: 'RightThumbstickUpRight',
      keyboard: '86',
      ps3: 'RightThumbstickUpRight',
      ps4: 'RightThumbstickUpRight',
      ps5: 'RightThumbstickUpRight',
      steamG1: 'TrackpadUpRight',
    ),
    GamepadInputType.rightThumbstickLeftRight: InputGlyphRow(
      assetName: 'RightThumbstickLeftRight',
      keyboard: '46',
      steamG1: 'TrackpadLeftRight',
    ),
    GamepadInputType.rightThumbstickUpDown: InputGlyphRow(
      assetName: 'RightThumbstickUpDown',
      keyboard: '82',
      steamG1: 'TrackpadUpDown',
    ),
    GamepadInputType.rightThumbstickButton: InputGlyphRow(
      assetName: 'RightThumbstickButton',
      keyboard: 'V',
      ps3: 'R3',
      ps4: 'R3',
      ps5: 'R3',
      switchJoyCon: 'RightThumbStickButton',
      steamG1: 'TrackpadCenter',
    ),
    GamepadInputType.homeButton: InputGlyphRow(
      assetName: 'HomeButton',
      keyboard: 'F1',
      xbox360: 'Home',
      xboxOne: 'Home',
      xboxSeriesXs: '',
      ps3: 'Home',
      ps4: 'Home',
      ps5: 'Home',
      wii: 'Home',
      switchJoyCon: 'Home',
      steamG1: 'Steam Button',
    ),
  },
);
