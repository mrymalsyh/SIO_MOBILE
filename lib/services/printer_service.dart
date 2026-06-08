import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class PrinterService {
  static String buildTSPLLabel({
    required String medicineName,
    required String referenceNumber,
    required String expiryDate,
    required String lotNumber,
  }) {
    return '''
SIZE 40 mm,30 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 25,10,"3",0,1,1,"$medicineName"
TEXT 25,40,"3",0,1,1,"Ref: $referenceNumber"
TEXT 25,70,"3",0,1,1,"Exp: $expiryDate"
BARCODE 35,100,"128",60,0,0,1,1,"$lotNumber"
TEXT 35,170,"2",0,1,1,"$lotNumber"
PRINT 1
''';
  }

  /// Test print
  static Future<void> testPrint(BuildContext context) async {
    try {
      const med = 'UBAT STRESS 100MG';
      const ref = '130205';
      const lot = 'MAC-AMN-A132-0143';
      final exp = DateTime.now()
          .add(const Duration(days: 365))
          .toString()
          .split(' ')[0];

      final cmd =
          '''
SIZE 40 mm,30 mm
GAP 2 mm,0
DENSITY 8
SPEED 4
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 25,10,"3",0,1,1,"$med"
TEXT 25,40,"3",0,1,1,"Ref: $ref"
TEXT 25,70,"3",0,1,1,"Exp: $exp"
BARCODE 55,100,"128",60,0,0,1,1,"$lot"
TEXT 35 ,170,"2",0,1,1,"$lot"
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

  /// Print list of lot labels
  static Future<void> printAllLots(
    BuildContext context,
    List<Map<String, dynamic>> lotList,
  ) async {
    try {
      for (final lot in lotList) {
        final cmd = buildTSPLLabel(
          medicineName: lot['medicine_name'] ?? '',
          referenceNumber: lot['reference_number'] ?? '',
          expiryDate: lot['expiry_date'] ?? '',
          lotNumber: lot['lot_number'] ?? '',
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
