class TsplFormatter {
  static String buildDoSerialLabels({
    required Map<String, dynamic> header,
    required List<Map<String, dynamic>> serials,
  }) {
    final buffer = StringBuffer();

    // Header info (available for future use if needed)
    for (final serial in serials) {
      final product = serial['ProductName'] ?? '';
      final serialNumber = serial['SerialNumber'] ?? '';

      buffer.writeln('SIZE 40 mm,30 mm');
      buffer.writeln('GAP 2 mm,0');
      buffer.writeln('CLS');
      buffer.writeln('TEXT 40,20,"2",0,1,1,"$product"');
      buffer.writeln('BARCODE 40,70,"128",60,0,0,2,2,"$serialNumber"');
      buffer.writeln('TEXT 40,140,"2",0,1,1,"$serialNumber"');
      buffer.writeln('PRINT 1,1');
    }

    return buffer.toString();
  }
}
