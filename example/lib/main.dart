import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:easy_blue_printer_example/bluetooth_controller.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Blue Printer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const PrinterPage(),
    );
  }
}

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final BluetoothController _controller = BluetoothController();

  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isLoading = false;
  bool _hasScanned = false;

  bool get _isConnected => _connectedDevice != null;

  Future<void> _scan() async {
    setState(() {
      _isScanning = true;
      _hasScanned = true;
    });
    await _controller.startScan();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.connectToDevice(device);
      if (success) {
        setState(() => _connectedDevice = device);
        _showSnackBar('Connected to ${device.name}', isError: false);
      } else {
        _showSnackBar('Failed to connect to ${device.name}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.disconnectFromDevice();
      if (success) {
        final name = _connectedDevice?.name ?? 'device';
        setState(() => _connectedDevice = null);
        _showSnackBar('Disconnected from $name', isError: false);
      } else {
        _showSnackBar('Failed to disconnect', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printText() async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.printData(
        data: 'Sucesso voce configurou a impressora!!',
        fontSize: FS.medium,
        textAlign: TA.center,
        bold: false,
      );
      await _controller.printEmptyLine(callTimes: 5);
      _showSnackBar(success ? 'Text printed successfully' : 'Print failed',
          isError: !success);
    } catch (e) {
      _showSnackBar('Print error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printImage() async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.printImage(
        path: 'assets/images/gremio.png',
        textAlign: TA.center,
      );
      _showSnackBar(success ? 'Image printed successfully' : 'Print failed',
          isError: !success);
    } catch (e) {
      _showSnackBar('Print error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    try {
      final connected = await _controller.isConnected();
      _showSnackBar(
          connected ? 'Printer is connected' : 'Printer is not connected',
          isError: !connected);
      if (!connected && _connectedDevice != null) {
        setState(() => _connectedDevice = null);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Blue Printer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Device list section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                      child: Row(
                        children: [
                          Icon(Icons.bluetooth,
                              size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Paired Devices',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                            icon: _isScanning
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            tooltip: 'Scan devices',
                            onPressed: _isScanning ? null : _scan,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _buildDeviceList()),
                  ],
                ),
              ),
            ),
          ),

          // Actions section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Actions',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _isScanning || _isLoading ? null : _scan,
                          icon: const Icon(Icons.search),
                          label: const Text('Scan'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _isConnected && !_isLoading ? _printText : null,
                          icon: const Icon(Icons.print),
                          label: const Text('Print Text'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              _isConnected && !_isLoading ? _printImage : null,
                          icon: const Icon(Icons.image),
                          label: const Text('Print Image'),
                        ),
                        OutlinedButton.icon(
                          onPressed: !_isLoading ? _testConnection : null,
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('Test'),
                        ),
                        if (_isConnected)
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _disconnect,
                            icon: const Icon(Icons.link_off),
                            label: const Text('Disconnect'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Loading overlay
      bottomNavigationBar: _isLoading ? const LinearProgressIndicator() : null,
    );
  }

  Widget _buildDeviceList() {
    if (!_hasScanned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_searching,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tap Scan to find paired devices',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<BluetoothDevice>>(
      stream: _controller.devicesStream,
      builder: (context, snapshot) {
        if (_isScanning) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.devices, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No paired devices found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        final devices = snapshot.data!;
        return ListView.separated(
          itemCount: devices.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
          itemBuilder: (context, index) {
            final device = devices[index];
            final isThisConnected = _connectedDevice?.address == device.address;

            return ListTile(
              leading: Icon(
                Icons.bluetooth,
                color: isThisConnected ? Colors.green : null,
              ),
              title: Text(
                device.name,
                style: TextStyle(
                  fontWeight:
                      isThisConnected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(device.address),
              trailing: isThisConnected
                  ? Chip(
                      label: const Text('Connected'),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade200),
                      labelStyle:
                          TextStyle(color: Colors.green.shade700, fontSize: 12),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: _isLoading ? null : () => _connect(device),
                    ),
              onTap: _isLoading
                  ? null
                  : isThisConnected
                      ? null
                      : () => _connect(device),
            );
          },
        );
      },
    );
  }
}
