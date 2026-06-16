import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import '../../services/printer_service.dart';
import '../../services/bluetooth_service.dart';
import '../../utils/storage_helper.dart';
import '../../theme/app_theme.dart';

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
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 1.5,
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.line),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.print, color: colors.accent),
                  title: Text('Bluetooth Printer Setup', style: TextStyle(color: colors.text)),
                  subtitle: Text('Pair and configure your printer', style: TextStyle(color: colors.muted)),
                  onTap: _openPrinterSetup,
                ),
                Divider(height: 1, color: colors.line),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: colors.text)),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('Bluetooth Printer Setup'),
        backgroundColor: colors.bg,
        actions: [
          if (_savedName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Saved: $_savedName',
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Available Printers",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.text),
                  ),
                  IconButton(
                    onPressed: _loadPairedPrinters,
                    icon: Icon(Icons.refresh, color: colors.muted),
                    tooltip: 'Refresh devices',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_scanning)
                Center(child: CircularProgressIndicator(color: colors.accent))
              else if (_devices.isEmpty)
                Center(child: Text('No paired Bluetooth printers found.', style: TextStyle(color: colors.muted)))
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
                            ? colors.accent.withValues(alpha: 0.1)
                            : colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colors.line),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.print, color: colors.text),
                          title: Text(d.name ?? 'Unknown', style: TextStyle(color: colors.text)),
                          subtitle: Text(d.address ?? '', style: TextStyle(color: colors.muted)),
                          trailing: connected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.accent,
                                    foregroundColor: colors.accentForeground,
                                  ),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.accentForeground,
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Test Print'),
                    onPressed: _testPrint,
                  ),
                ),
              if (_connectedDevice != null)
                Center(
                  child: TextButton(
                    onPressed: _disconnectPrinter,
                    child: Text('Disconnect', style: TextStyle(color: colors.text)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
