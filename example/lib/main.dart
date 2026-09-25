import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  runApp(const GamepadGlyphExampleApp());
}

class GamepadGlyphExampleApp extends StatefulWidget {
  const GamepadGlyphExampleApp({super.key});

  @override
  State<GamepadGlyphExampleApp> createState() => _GamepadGlyphExampleAppState();
}

class _GamepadGlyphExampleAppState extends State<GamepadGlyphExampleApp> {
  final _inputDevices = InputDeviceTracker();
  late final GamepadGlyphs _gamepadGlyphs;

  @override
  void initState() {
    super.initState();
    _gamepadGlyphs = GamepadGlyphs(inputDevices: _inputDevices);
    _gamepadGlyphs.startInputTracking();
  }

  @override
  void dispose() {
    _gamepadGlyphs.stopInputTracking();
    _inputDevices.dispose();
    super.dispose();
  }

  void _selectDevice(int? vendorId, int? productId, InputDeviceKind inputKind) {
    _inputDevices.updateHardwareIds(vendorId, productId, inputKind: inputKind);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GamepadGlyph example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Scaffold(
        backgroundColor: Colors.grey.shade300,
        body: Stack(
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.contain,
                  child: _DemoContent(
                    inputDevices: _inputDevices,
                    onDeviceSelected: _selectDevice,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 40,
              child: ValueListenableBuilder<String>(
                valueListenable: _inputDevices,
                builder: (context, device, child) => _DeviceStatus(
                  vendorId: _inputDevices.vendorId,
                  productId: _inputDevices.productId,
                ),
              ),
            ),
            Positioned(
              left: 40,
              bottom: 40,
              child: Builder(
                builder: (buttonContext) => ExcludeFocus(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(buttonContext).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const _GlyphMapScreen(),
                      ),
                    ),
                    child: const Text('Show Map'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DemoMode { gamepad, tvRemote }

class _DemoContent extends StatefulWidget {
  const _DemoContent({
    required this.inputDevices,
    required this.onDeviceSelected,
  });

  final InputDeviceTracker inputDevices;
  final void Function(int? vendorId, int? productId, InputDeviceKind inputKind)
  onDeviceSelected;

  @override
  State<_DemoContent> createState() => _DemoContentState();
}

class _DemoContentState extends State<_DemoContent> {
  _DemoMode _mode = _DemoMode.gamepad;

  InputDeviceTracker get inputDevices => widget.inputDevices;

  void Function(int?, int?, InputDeviceKind) get onDeviceSelected =>
      widget.onDeviceSelected;

  @override
  Widget build(BuildContext context) {
    void selectGamepad(int vendorId, int productId) =>
        onDeviceSelected(vendorId, productId, InputDeviceKind.gamepad);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Click to Simulate Input Device',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        ExcludeFocus(
          child: SizedBox(
            width: 880,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _mode == _DemoMode.gamepad
                    ? Column(
                        key: const ValueKey<_DemoMode>(_DemoMode.gamepad),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  _SimulationButton(
                                    label: 'Xbox 360',
                                    onPressed: () => selectGamepad(1118, 654),
                                  ),
                                  _SimulationButton(
                                    label: 'Xbox One',
                                    onPressed: () => selectGamepad(1118, 721),
                                  ),
                                  _SimulationButton(
                                    label: 'Xbox Series X|S',
                                    onPressed: () => selectGamepad(1118, 2834),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _SimulationButton(
                                    label: 'DualShock 3 (PS3)',
                                    onPressed: () => selectGamepad(1356, 616),
                                  ),
                                  _SimulationButton(
                                    label: 'DualShock 4 (PS4)',
                                    onPressed: () => selectGamepad(1356, 1476),
                                  ),
                                  _SimulationButton(
                                    label: 'DualSense (PS5)',
                                    onPressed: () => selectGamepad(1356, 3302),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _SimulationButton(
                                    label: 'Switch Joy-Con',
                                    onPressed: () => selectGamepad(1406, 8206),
                                  ),
                                  _SimulationButton(
                                    label: 'Switch Pro',
                                    onPressed: () => selectGamepad(1406, 8201),
                                  ),
                                  _SimulationButton(
                                    label: 'SNES',
                                    onPressed: () =>
                                        selectGamepad(11720, 24577),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _SimulationButton(
                                    label: 'Steam (G1)',
                                    onPressed: () => selectGamepad(10462, 4354),
                                  ),
                                  _SimulationButton(
                                    label: 'Steam (G2)',
                                    onPressed: () => selectGamepad(10462, 4866),
                                  ),
                                  _SimulationButton(
                                    label: 'Arcade Fight Stick',
                                    onPressed: () => selectGamepad(3090, 3120),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _SimulationButton(
                            label: 'Keyboard',
                            onPressed: () => onDeviceSelected(
                              null,
                              null,
                              InputDeviceKind.keyboard,
                            ),
                          ),
                        ],
                      )
                    : _buildRemoteButtons(),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: SizedBox(
            width: 780,
            height: 300,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _mode == _DemoMode.gamepad
                  ? Row(
                      key: const ValueKey<_DemoMode>(_DemoMode.gamepad),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 390,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: 360,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PromptRow(
                                      label: 'Change Selection',
                                      input: 'ls_up_down',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Change Mode',
                                      input: 'lb_rb',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Help',
                                      input: 'Y',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'More Info',
                                      input: 'X',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Go Back',
                                      input: 'B',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Select Item',
                                      input: 'A',
                                      deviceListenable: inputDevices,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 390,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: 360,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PromptRow(
                                      label: 'Scroll',
                                      input: 'rs_left_right',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Skip',
                                      input: 'rs_cw',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Cycle',
                                      input: 'dp',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Jump',
                                      input: 'lt_rt',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Context',
                                      input: 'view',
                                      deviceListenable: inputDevices,
                                    ),
                                    _PromptRow(
                                      label: 'Settings',
                                      input: 'menu',
                                      deviceListenable: inputDevices,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildRemoteGlyphs(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          child: _buildModeSelector(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<_DemoMode>(
      segments: const <ButtonSegment<_DemoMode>>[
        ButtonSegment<_DemoMode>(
          value: _DemoMode.gamepad,
          label: Text('Gamepad'),
        ),
        ButtonSegment<_DemoMode>(
          value: _DemoMode.tvRemote,
          label: Text('TV Remote'),
        ),
      ],
      selected: <_DemoMode>{_mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() => _mode = selection.single);
      },
    );
  }

  Widget _buildRemoteButtons() {
    return Wrap(
      key: const ValueKey<_DemoMode>(_DemoMode.tvRemote),
      alignment: WrapAlignment.center,
      children: [
        _SimulationButton(
          label: 'TV Remote',
          onPressed: () => onDeviceSelected(null, null, InputDeviceKind.remote),
        ),
        _SimulationButton(
          label: 'Apple TV',
          onPressed: () => inputDevices.updateHardwareIds(
            null,
            null,
            inputKind: InputDeviceKind.remote,
            productCategory: 'GCProductCategorySiriRemote2ndGen',
          ),
        ),
        _SimulationButton(
          label: 'Google TV',
          onPressed: () => onDeviceSelected(6353, 945, InputDeviceKind.remote),
        ),
        _SimulationButton(
          label: 'Fire TV',
          onPressed: () => onDeviceSelected(7439, null, InputDeviceKind.remote),
        ),
        _SimulationButton(
          label: 'Xbox One',
          onPressed: () => onDeviceSelected(1118, 721, InputDeviceKind.gamepad),
        ),
        _SimulationButton(
          label: 'Keyboard',
          onPressed: () =>
              onDeviceSelected(null, null, InputDeviceKind.keyboard),
        ),
      ],
    );
  }

  Widget _buildRemoteGlyphs() {
    return Row(
      key: const ValueKey<_DemoMode>(_DemoMode.tvRemote),
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRemoteGlyph('dp_left', 'Left'),
              _buildRemoteGlyph('a', 'OK'),
              _buildRemoteGlyph('b', 'Back'),
              _buildRemoteGlyph('dp_right', 'Right'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRemoteGlyph('lt', 'Rewind'),
              _buildRemoteGlyph('rt', 'Fast Forward'),
              _buildRemoteGlyph('home', 'Home'),
              _buildRemoteGlyph('voice', 'Voice'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteGlyph(String input, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 30),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 60,
            child: Center(
              child: GamepadGlyph(input: input, deviceListenable: inputDevices),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationButton extends StatelessWidget {
  const _SimulationButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.label,
    required this.input,
    required this.deviceListenable,
  });

  final String label;
  final String input;
  final ValueListenable<String> deviceListenable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox.square(
            dimension: 50,
            child: Center(
              child: GamepadGlyph(
                input: input,
                deviceListenable: deviceListenable,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _DeviceStatus extends StatelessWidget {
  const _DeviceStatus({this.vendorId, this.productId});

  final int? vendorId;
  final int? productId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vendor ID: ${_formatId(vendorId)}'),
        Text('Product ID: ${_formatId(productId)}'),
      ],
    );
  }

  static String _formatId(int? id) {
    return id == null ? '' : id.toRadixString(16).padLeft(4, '0').toUpperCase();
  }
}

class _GlyphMapScreen extends StatefulWidget {
  const _GlyphMapScreen();

  @override
  State<_GlyphMapScreen> createState() => _GlyphMapScreenState();
}

class _GlyphMapScreenState extends State<_GlyphMapScreen> {
  final _scrollController = ScrollController();

  static const _semanticColumnWidth = 180.0;
  static const _deviceColumnWidth = 100.0;

  static const _devices = <String>[
    'Arcade',
    'Xbox 360',
    'Xbox One',
    'Xbox Series X-S',
    'PS3',
    'PS4',
    'PS5',
    'Switch Joy-Con',
    'Switch Pro',
    'Steam (G1)',
    'Steam (G2)',
    'Keyboard',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputs = const <String>[
      'Y',
      'A',
      'B',
      'X',
      'view',
      'menu',
      'lb',
      'rb',
      'lb_rb',
      'lt',
      'rt',
      'lt_rt',
      'lsb',
      'rsb',
      'dp',
      'dpUp',
      'dpDown',
      'dpLeft',
      'dpRight',
      'dpUpLeft',
      'dpUpRight',
      'dpDownLeft',
      'dpDownRight',
      'dpUpDown',
      'dpLeftRight',
      'ls',
      'lsCw',
      'lsCcw',
      'lsUp',
      'lsDown',
      'lsLeft',
      'lsRight',
      'lsUpLeft',
      'lsUpRight',
      'lsDownLeft',
      'lsDownRight',
      'lsUpDown',
      'lsLeftRight',
      'rs',
      'rsCw',
      'rsCcw',
      'rsUp',
      'rsDown',
      'rsLeft',
      'rsRight',
      'rsUpLeft',
      'rsUpRight',
      'rsDownLeft',
      'rsDownRight',
      'rsUpDown',
      'rsLeftRight',
      'home',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Glyph Map'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerColumns = [
            const DataColumn(
              label: SizedBox(
                width: _semanticColumnWidth,
                child: Text('Semantic input', textAlign: TextAlign.center),
              ),
            ),
            ..._devices.map(
              (device) => DataColumn(
                label: SizedBox(
                  width: _deviceColumnWidth,
                  child: Text(device, textAlign: TextAlign.center),
                ),
              ),
            ),
          ];
          final bodyColumns = [
            const DataColumn(
              label: SizedBox(width: _semanticColumnWidth, height: 0),
            ),
            ..._devices.map(
              (_) => const DataColumn(
                label: SizedBox(width: _deviceColumnWidth, height: 0),
              ),
            ),
          ];
          final bodyRows = inputs
              .map(
                (input) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: _semanticColumnWidth,
                        child: Text(
                          input,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ..._devices.map(
                      (device) => DataCell(
                        SizedBox(
                          width: _deviceColumnWidth,
                          child: _MapGlyphCell(input: input, device: device),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList();

          return Column(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStatePropertyAll(
                      Colors.indigo.withValues(alpha: 0.12),
                    ),
                    columns: headerColumns,
                    rows: const [],
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topLeft,
                        child: DataTable(
                          columnSpacing: 16,
                          horizontalMargin: 12,
                          dataRowMinHeight: 72,
                          dataRowMaxHeight: 72,
                          headingRowHeight: 0,
                          columns: bodyColumns,
                          rows: bodyRows,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapGlyphCell extends StatelessWidget {
  const _MapGlyphCell({required this.input, required this.device});

  final String input;
  final String device;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GamepadGlyph(input: input, device: device, width: 42, height: 42),
    );
  }
}
