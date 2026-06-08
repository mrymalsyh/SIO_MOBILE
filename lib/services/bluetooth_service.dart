import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../utils/storage_helper.dart';

class BluetoothService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  /// Get paired printers
  static Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Connect and save printer
  static Future<void> connect(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    try {
      await _bluetooth.connect(device);
      await StorageHelper.savePrinter(device.name ?? '', device.address ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Connected to ${device.name ?? "Printer"}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Connection failed: $e')));
      }
    }
  }

  /// Disconnect printer
  static Future<void> disconnect(BuildContext context) async {
    try {
      await _bluetooth.disconnect();
      await StorageHelper.clearPrinter();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔌 Disconnected printer')),
        );
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  /// Check if still connected or reconnect saved printer silently
  static Future<bool> ensureConnected() async {
    final connected = await _bluetooth.isConnected ?? false;
    if (connected) return true;

    final saved = await StorageHelper.getSavedPrinter();
    if (saved == null) return false;

    try {
      final devices = await _bluetooth.getBondedDevices();
      final match = devices.firstWhere(
        (d) => d.address == saved['address'],
        orElse: () => BluetoothDevice.fromMap({'name': '', 'address': ''}),
      );
      if (match.address?.isEmpty ?? true) return false;
      await _bluetooth.connect(match);
      return true;
    } catch (e) {
      debugPrint('Reconnect failed: $e');
      return false;
    }
  }

  /// Send TSPL command
  static Future<void> sendCommand(String command) async {
    final connected = await ensureConnected();
    if (!connected) throw Exception('Printer not connected.');
    await _bluetooth.write(command);
  }
}
