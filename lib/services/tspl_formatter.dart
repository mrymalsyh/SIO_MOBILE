class TsplFormatter {
  static String buildDoLotLabels({
    required Map<String, dynamic> header,
    required List<Map<String, dynamic>> lots,
  }) {
    final buffer = StringBuffer();

    // Header info (available for future use if needed)
    // final doNumber = header['DO_Number'] ?? '';
    // final supplier = header['SupplierName'] ?? '';

    for (final lot in lots) {
      final product = lot['ProductName'] ?? '';
      final ref = lot['RefNum'] ?? '';
      final expiry = lot['ExpiryDate'] ?? '';
      final lotNumber = lot['LotNumber'] ?? '';

      buffer.writeln('SIZE 40 mm,30 mm');
      buffer.writeln('GAP 2 mm,0');
      buffer.writeln('CLS');
      buffer.writeln('TEXT 40,20,"3",0,1,1,"$product"');
      buffer.writeln('TEXT 40,50,"3",0,1,1,"Ref: $ref"');
      buffer.writeln('TEXT 40,80,"3",0,1,1,"Exp: $expiry"');
      buffer.writeln('BARCODE 40,120,"128",60,0,0,2,2,"$lotNumber"');
      buffer.writeln('TEXT 40,190,"3",0,1,1,"Lot: $lotNumber"');
      buffer.writeln('PRINT 1,1');
    }

    return buffer.toString();
  }
}
