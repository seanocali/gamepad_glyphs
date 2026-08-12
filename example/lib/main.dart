import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamepad_glyphs/gamepad_glyphs.dart';

void main() {
  runApp(const InputPromptExampleApp());
}

class InputPromptExampleApp extends StatefulWidget {
  const InputPromptExampleApp({super.key});

  @override
  State<InputPromptExampleApp> createState() => _InputPromptExampleAppState();
}

class _InputPromptExampleAppState extends State<InputPromptExampleApp> {
  final _inputDevices = InputDeviceTracker();
  late final GamepadGlyphs _gamepadGlyphs;
  bool _useMonochrome = false;

  @override
  void initState() {
    super.initState();
    _gamepadGlyphs = GamepadGlyphs(inputDevices: _inputDevices);
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _gamepadGlyphs.startInputTracking();
    }
  }

  @override
  void dispose() {
    _gamepadGlyphs.stopInputTracking();
    _inputDevices.dispose();
    super.dispose();
  }

  void _selectDevice(int? vendorId, int? productId) {
    _inputDevices.updateHardwareIds(vendorId, productId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InputPrompt example',
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
                    useMonochrome: _useMonochrome,
                    inputDevices: _inputDevices,
                    onMonochromeChanged: (value) =>
                        setState(() => _useMonochrome = value),
                    onDeviceSelected: _selectDevice,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 40,
              child: ValueListenableBuilder<InputDeviceProfile>(
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

class _DemoContent extends StatelessWidget {
  const _DemoContent({
    required this.useMonochrome,
    required this.inputDevices,
    required this.onMonochromeChanged,
    required this.onDeviceSelected,
  });

  final bool useMonochrome;
  final InputDeviceTracker inputDevices;
  final ValueChanged<bool> onMonochromeChanged;
  final void Function(int? vendorId, int? productId) onDeviceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Alternate between keyboard input and gamepad input\n'
          'and observe the behavior in the box below',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 10),
        ExcludeFocus(
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: useMonochrome,
                    onChanged: (value) => onMonochromeChanged(value ?? false),
                  ),
                  const Text('Use Monochrome Icons'),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _SimulationButton(
                        label: 'Simulate Xbox 360 Gamepad Input',
                        onPressed: () => onDeviceSelected(1118, 702),
                      ),
                      _SimulationButton(
                        label: 'Simulate Xbox One Gamepad Input',
                        onPressed: () => onDeviceSelected(1118, 721),
                      ),
                      _SimulationButton(
                        label: 'Simulate PlayStation 4 DualShock Input',
                        onPressed: () => onDeviceSelected(1356, 1476),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      _SimulationButton(
                        label: 'Simulate PlayStation 5 DualSense Input',
                        onPressed: () => onDeviceSelected(1356, 3302),
                      ),
                      _SimulationButton(
                        label: 'Simulate Nintendo Switch Pro Input',
                        onPressed: () => onDeviceSelected(1406, 8201),
                      ),
                      _SimulationButton(
                        label: 'Simulate Keyboard Input',
                        onPressed: () => onDeviceSelected(null, null),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              _PromptRow(
                label: 'Change Selection',
                input: GamepadInputType.leftThumbstickUpDown,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
              _PromptRow(
                label: 'Change Mode',
                input: GamepadInputType.leftRightShoulder,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
              _PromptRow(
                label: 'Help',
                input: GamepadInputType.north,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
              _PromptRow(
                label: 'More Info',
                input: GamepadInputType.west,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
              _PromptRow(
                label: 'Go Back',
                input: GamepadInputType.east,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
              _PromptRow(
                label: 'Select Item',
                input: GamepadInputType.south,
                deviceListenable: inputDevices,
                useMonochrome: useMonochrome,
              ),
            ],
          ),
        ),
      ],
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
      width: 300,
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
    required this.useMonochrome,
  });

  final String label;
  final GamepadInputType input;
  final ValueListenable<InputDeviceProfile> deviceListenable;
  final bool useMonochrome;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: InputPrompt(
            input: input,
            deviceListenable: deviceListenable,
            useMonochrome: useMonochrome,
            width: 50,
            height: 50,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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

  static const _devices = <(String, InputDeviceModel)>[
    ('Xbox 360', InputDeviceModel.xbox360),
    ('Xbox One', InputDeviceModel.xboxOne),
    ('PS3', InputDeviceModel.ps3),
    ('PS4', InputDeviceModel.ps4),
    ('PS5', InputDeviceModel.ps5),
    ('Switch Pro', InputDeviceModel.switchPro),
    ('Keyboard', InputDeviceModel.keyboard),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = defaultInputGlyphs.rows.entries;

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
        builder: (context, constraints) => Scrollbar(
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
                  dataRowMinHeight: 120,
                  dataRowMaxHeight: 120,
                  headingRowColor: WidgetStatePropertyAll(
                    Colors.indigo.withValues(alpha: 0.12),
                  ),
                  columns: [
                    const DataColumn(
                      label: SizedBox(
                        width: _semanticColumnWidth,
                        child: Text(
                          'Semantic input',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    ..._devices.map(
                      (device) => DataColumn(
                        label: SizedBox(
                          width: _deviceColumnWidth,
                          child: Text(device.$1, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                  rows: rows
                      .map(
                        (entry) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: _semanticColumnWidth,
                                child: Text(
                                  entry.key.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ..._devices.map(
                              (device) => DataCell(
                                SizedBox(
                                  width: _deviceColumnWidth,
                                  child: _MapGlyphCell(
                                    input: entry.key,
                                    device: device.$2,
                                    glyphName: entry.value.glyphName(device.$2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGlyphCell extends StatelessWidget {
  const _MapGlyphCell({
    required this.input,
    required this.device,
    required this.glyphName,
  });

  final GamepadInputType input;
  final InputDeviceModel device;
  final String? glyphName;

  @override
  Widget build(BuildContext context) {
    if (glyphName == null) return const Text('—');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InputPrompt(
            input: input,
            device: InputDeviceProfile(device),
            width: 42,
            height: 42,
          ),
          Text(glyphName!, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
