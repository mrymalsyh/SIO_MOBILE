import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class PrinterService {
  static String _sanitizeTsplText(String value) {
    return value
        .replaceAll('"', "'")
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String buildTSPLLabel({
    required String productName,
    required String serialNumber,
  }) {
    final safeProductName = _sanitizeTsplText(productName);
    final safeSerialNumber = _sanitizeTsplText(serialNumber);
    final buffer = StringBuffer();
    buffer.writeln('SIZE 40 mm,30 mm');
    buffer.writeln('GAP 2 mm,0');
    buffer.writeln('DENSITY 8');
    buffer.writeln('SPEED 4');
    buffer.writeln('DIRECTION 1');
    buffer.writeln('REFERENCE 0,0');
    buffer.writeln('CLS');

    if (safeProductName.length < 12) {
      buffer.writeln('TEXT 48,20,"1",0,1,2,"$safeProductName"');
    } else {
      int mid = safeProductName.length ~/ 2;
      int splitIndex = safeProductName.lastIndexOf(' ', mid + 5);
      if (splitIndex <= 0) {
        splitIndex = mid;
      }
      String line1 = safeProductName.substring(0, splitIndex).trim();
      String line2 = safeProductName.substring(splitIndex).trim();

      buffer.writeln('TEXT 48,30,"1",0,1,2,"$line1"');
      buffer.writeln('TEXT 48,65,"1",0,1,2,"$line2"');
    }

    buffer.writeln('BARCODE 38,100,"128",60,0,0,1,1,"$safeSerialNumber"');
    buffer.writeln('TEXT 58,170,"1",0,1,2,"$safeSerialNumber"');
    buffer.writeln('PRINT 1');

    return buffer.toString();
  }

  /// Test print
  static Future<void> testPrint(BuildContext context) async {
    try {
      const med = 'Mysztech';
         const serial = 'TP80-USBBT-20260615-0001';

      final cmd = buildTSPLLabel(
        productName: med,
        serialNumber: serial,    
      );

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
        ).showSnackBar(SnackBar(content: Text('❌ Test print unsuccessful: $e')));
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
          productName: serial['product_name'] ?? '',
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
