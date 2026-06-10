import 'package:flutter/material.dart';

import '../services/keyboard_service.dart';

class KeyboardDebugScreen extends StatefulWidget {
  static const String routeName = '/keyboard-debug';

  const KeyboardDebugScreen({Key? key}) : super(key: key);

  @override
  State<KeyboardDebugScreen> createState() => _KeyboardDebugScreenState();
}

class _KeyboardDebugScreenState extends State<KeyboardDebugScreen> {
  final KeyboardService _keyboardService = KeyboardService();

  bool _isEnabled = false;
  bool _isSelected = false;
  bool _hasFullAccess = false;
  bool _hasFullAccessRuntime = false;
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;
  double _lastTimestamp = 0.0;
  String _currentKeyboardName = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkKeyboardStatus();
  }

  Future<void> _checkKeyboardStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isEnabled = await _keyboardService.isCustomKeyboardEnabled();
      final isSelected = await _keyboardService.isCustomKeyboardSelected();
      final hasFullAccessRuntime =
          await _keyboardService.hasFullAccessRuntime();
      final debugInfo = await _keyboardService.getKeyboardDebugInfo();
      final currentKeyboardName = await _keyboardService.getCurrentSelectedKeyboardName();

      setState(() {
        _isEnabled = isEnabled;
        _isSelected = isSelected;
        _hasFullAccessRuntime = hasFullAccessRuntime;
        _debugInfo = debugInfo;
        _currentKeyboardName = currentKeyboardName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking keyboard status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keyboard Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const TextField(),
                    const SizedBox(height: 16),
                    _buildStatusRow('Enabled', _isEnabled),
                    _buildStatusRow('Selected', _isSelected),
                    _buildStatusRow('Full Access', _hasFullAccess),
                    _buildStatusRow(
                        'Full Access (Runtime)', _hasFullAccessRuntime),
                    _buildTimestampRow('Last Timestamp', _lastTimestamp),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCurrentKeyboardCard(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ..._debugInfo.entries.map((entry) =>
                        _buildDebugRow(entry.key, entry.value.toString())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkKeyboardStatus,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Refresh Status'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await _keyboardService.openKeyboardSettings();
                          },
                    child: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value ? 'YES' : 'NO',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentKeyboardCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Keyboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    _currentKeyboardName.isNotEmpty ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentKeyboardName.isNotEmpty
                          ? _currentKeyboardName
                          : 'NO DATA',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final keyboardName = await _keyboardService
                                .getCurrentSelectedKeyboardName();
                            setState(() {
                              _currentKeyboardName = keyboardName;
                            });
                          },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardNameRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value.isNotEmpty ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.isNotEmpty ? value : 'NO DATA',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, double timestamp) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).round());
    final formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: timestamp > 0 ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timestamp > 0 ? formattedTime : 'NO DATA',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
