import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../../services/printer_service.dart';
import '../../services/bluetooth_service.dart';
import '../../utils/storage_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openPrinterSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BluetoothPrinterSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.print, color: Colors.indigo),
                  title: const Text('Bluetooth Printer Setup'),
                  subtitle: const Text('Pair and configure your printer'),
                  onTap: _openPrinterSetup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Logout'),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BluetoothPrinterSetupScreen extends StatefulWidget {
  const BluetoothPrinterSetupScreen({super.key});

  @override
  State<BluetoothPrinterSetupScreen> createState() =>
      _BluetoothPrinterSetupScreenState();
}

class _BluetoothPrinterSetupScreenState
    extends State<BluetoothPrinterSetupScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  bool _scanning = false;
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  Future<void> _initializePrinter() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final saved = await StorageHelper.getSavedPrinter();
    _savedName = saved?['name'];

    final connected = await BluetoothService.ensureConnected();
    setState(() {
      _connectedDevice = connected
          ? BluetoothDevice.fromMap(saved ?? {})
          : null;
    });

    await _loadPairedPrinters();
  }

  Future<void> _loadPairedPrinters() async {
    setState(() => _scanning = true);
    final list = await BluetoothService.getBondedDevices();
    setState(() {
      _devices = list;
      _scanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await BluetoothService.connect(context, device);
    setState(() {
      _connectedDevice = device;
      _savedName = device.name;
    });
  }

  Future<void> _disconnectPrinter() async {
    await BluetoothService.disconnect(context);
    setState(() {
      _connectedDevice = null;
      _savedName = null;
    });
  }

  Future<void> _testPrint() async {
    await PrinterService.testPrint(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printer Setup'),
        actions: [
          if (_savedName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Saved: $_savedName',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Available Printers",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _loadPairedPrinters,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh devices',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_scanning)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              const Center(child: Text('No paired Bluetooth printers found.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final d = _devices[index];
                    final connected =
                        _connectedDevice != null &&
                        d.address == _connectedDevice?.address;

                    return Card(
                      color: connected
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : Colors.white,
                      child: ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(d.name ?? 'Unknown'),
                        subtitle: Text(d.address ?? ''),
                        trailing: connected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : ElevatedButton(
                                onPressed: () => _connectToDevice(d),
                                child: const Text('Connect'),
                              ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            if (_connectedDevice != null)
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Test Print'),
                  onPressed: _testPrint,
                ),
              ),
            if (_connectedDevice != null)
              Center(
                child: TextButton(
                  onPressed: _disconnectPrinter,
                  child: const Text('Disconnect'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
