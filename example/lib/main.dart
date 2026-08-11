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

  @override
  void dispose() {
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
        appBar: AppBar(title: const Text('InputPrompt example')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<InputDeviceProfile>(
                  valueListenable: _inputDevices,
                  builder: (context, device, child) => Text(
                    'Last input: ${device.model.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _selectDevice(null, null),
                      child: const Text('Keyboard'),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectDevice(1118, 721),
                      child: const Text('Xbox One'),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectDevice(1356, 1476),
                      child: const Text('PlayStation 4'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _PromptRow(
                  label: 'Select Item',
                  input: GamepadInputType.a,
                  deviceListenable: _inputDevices,
                ),
                _PromptRow(
                  label: 'Go Back',
                  input: GamepadInputType.b,
                  deviceListenable: _inputDevices,
                ),
                _PromptRow(
                  label: 'Change Selection',
                  input: GamepadInputType.leftThumbstickUpDown,
                  deviceListenable: _inputDevices,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.label,
    required this.input,
    this.deviceListenable,
  });

  final String label;
  final GamepadInputType input;
  final ValueListenable<InputDeviceProfile>? deviceListenable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InputPrompt(
            input: input,
            deviceListenable: deviceListenable,
            width: 56,
            height: 56,
          ),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
