import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class PrinterService {
  static String buildTSPLLabel({
    required String medicineName,
    required String serialNumber,
  }) {
    return '''
SIZE 40 mm,30 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 25,20,"2",0,1,1,"$medicineName"
BARCODE 35,70,"128",60,0,0,1,1,"$serialNumber"
TEXT 35,140,"2",0,1,1,"$serialNumber"
PRINT 1
''';
  }

  /// Test print
  static Future<void> testPrint(BuildContext context) async {
    try {
      const med = 'THERMAL PRINTER USB BLUETOOTH AUTOCUT (80MM)';
      const serial = 'TP80-USBBT-20260615-0001';

      final cmd =
          '''
SIZE 40 mm,30 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 25,20,"2",0,1,1,"$med"
BARCODE 35,70,"128",60,0,0,1,1,"$serial"
TEXT 35,140,"2",0,1,1,"$serial"
PRINT 1
''';

      await BluetoothService.sendCommand(cmd);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🖨️ Test label printed successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Test print failed: $e')));
      }
    }
  }

  /// Print list of serial labels
  static Future<void> printAllSerials(
    BuildContext context,
    List<Map<String, dynamic>> serialList,
  ) async {
    try {
      for (final serial in serialList) {
        final cmd = buildTSPLLabel(
          medicineName: serial['medicine_name'] ?? '',
          serialNumber: serial['serial_number'] ?? '',
        );
        await BluetoothService.sendCommand(cmd);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ All labels printed.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Print failed: $e')));
      }
    }
  }
}
