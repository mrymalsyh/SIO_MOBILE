import 'package:flutter_test/flutter_test.dart';
import 'package:sio/services/printer_service.dart';

void main() {
  group('PrinterService Tests', () {
    test('buildTSPLLabel centers barcode and serial number', () {
      final label = PrinterService.buildTSPLLabel(
        productName: 'Test Product',
        serialNumber: '123456789012345',
      );

      // Verify that BARCODE uses center alignment calculated dynamically
      expect(
        label,
        contains('BARCODE 98,100,"128",60,0,0,1,1,"123456789012345"'),
      );

      // Verify that TEXT uses center alignment calculated dynamically
      expect(
        label,
        contains('TEXT 100,170,"1",0,1,2,"123456789012345"'),
      );
    });

    test('buildTSPLLabel centers barcode and serial number for long serial', () {
      final label = PrinterService.buildTSPLLabel(
        productName: 'Test Product',
        serialNumber: 'VERYLONGSERIALNUMBER12345678901234567890',
      );

      // For long serials exceeding the label width, it clamps starting X to 0
      expect(
        label,
        contains('BARCODE 0,100,"128",60,0,0,1,1,"VERYLONGSERIALNUMBER12345678901234567890"'),
      );

      expect(
        label,
        contains('TEXT 0,170,"1",0,1,2,"VERYLONGSERIALNUMBER12345678901234567890"'),
      );
    });
  });
}
