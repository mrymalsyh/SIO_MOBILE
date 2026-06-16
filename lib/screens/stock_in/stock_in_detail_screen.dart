import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/printer_service.dart';
import '../../theme/app_theme.dart';

/// Stock-In Detail Screen matching SIO web frontend styling
class StockInDetailScreen extends StatefulWidget {
  final int stockInId;
  final String stockInNumber;
  final String supplierName;
  final String receiveDate;

  const StockInDetailScreen({
    super.key,
    required this.stockInId,
    required this.stockInNumber,
    required this.supplierName,
    required this.receiveDate,
  });

  @override
  State<StockInDetailScreen> createState() => _StockInDetailScreenState();
}

class _StockInDetailScreenState extends State<StockInDetailScreen> {
  final _api = ApiService();

  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _header = {};

  @override
  void initState() {
    super.initState();
    _load();
    _checkRole();
  }

  Future<void> _checkRole() async {
    await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final response = await _api.getStockInDetail(context, id: widget.stockInId);

    setState(() {
      if (response != null && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        _rows = List<Map<String, dynamic>>.from(data['lines'] ?? []);
        _header = {
          'DO_Number': data['stock_in_number'] ?? widget.stockInNumber,
          'SupplierName': data['supplier_name'] ?? widget.supplierName,
          'ReceiveDate': data['stock_in_date'] ?? widget.receiveDate,
          'PIC': '-', // Add PIC if SIO_BE adds it later
        };
      }
      _loading = false;
    });
  }

  // Group rows by product
  List<Map<String, dynamic>> get _grouped {
    final Map<int, Map<String, dynamic>> groups = {};

    for (var row in _rows) {
      final productId = row['product_id'] ?? 0;
      final productName = row['product_name'] ?? '-';
      final productCode = row['product_code'];

      if (!groups.containsKey(productId)) {
        groups[productId] = {
          'ProductID': productId,
          'ProductName': productName,
          'ProductCode': productCode,
          'Serials': <Map<String, dynamic>>[],
          'Items': <Map<String, dynamic>>[],
        };
      }

      groups[productId]!['Items'].add(row);

      final items = row['stock_items'] as List? ?? [];
      for (var item in items) {
        groups[productId]!['Serials'].add(Map<String, dynamic>.from(item));
      }
    }

    return groups.values.toList();
  }

  int get _totalQty => _rows.fold<int>(
    0,
    (sum, row) => sum + (int.tryParse('${row['received_qty'] ?? 0}') ?? 0),
  );

  int get _totalSerials {
    int count = 0;
    for (var row in _rows) {
      final items = row['stock_items'] as List? ?? [];
      count += items.length;
    }
    return count > 0 ? count : _totalQty;
  }

  Future<void> _onPrint() async {
    final generatedItems = <Map<String, dynamic>>[];

    for (var row in _rows) {
      final productName = row['product_name'] ?? '-';
      final productCode = row['product_code'] ?? '';
      final items = row['stock_items'] as List? ?? [];

      for (var item in items) {
        if (item['serial_source'] == 'GENERATED') {
          generatedItems.add({
            'product_name': productName,
            'product_code': productCode,
            'expiry_date':
                '', // SIO_BE doesn't seem to have expiry at item level
            'serial_number': item['serial_number'] ?? '',
          });
        }
      }
    }

    if (generatedItems.isEmpty) {
      _showSnack('No generated serial numbers to print.');
      return;
    }

    try {
      await PrinterService.printAllSerials(context, generatedItems);
    } catch (e) {
      _showSnack('Print failed: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.stockInNumber,
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onPrint,
            icon: const Icon(Icons.print_outlined),
            color: colors.accent,
            tooltip: 'Print Labels',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildSerialsList(context)),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info row
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _headerItem(
                context,
                Icons.description_outlined,
                'DO: ${widget.stockInNumber}',
              ),
              _headerItem(
                context,
                Icons.apartment,
                _header['SupplierName'] ?? widget.supplierName,
              ),
              _headerItem(
                context,
                Icons.calendar_today_outlined,
                _header['ReceiveDate'] ?? widget.receiveDate,
              ),
              _headerItem(
                context,
                Icons.person_outline,
                'PIC: ${_header['PIC'] ?? '-'}',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats chips
          Row(
            children: [
              _buildStatChip(
                icon: Icons.inventory_2_outlined,
                label: 'Total Qty',
                value: _totalQty.toString(),
                color: colors.accent,
                bgColor: colors.accent.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.tag,
                label: 'Serials',
                value: _totalSerials.toString(),
                color: const Color(0xFF22C55E),
                bgColor: const Color(0xFFDCFCE7).withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerItem(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.muted),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: colors.text)),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialsList(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: colors.muted),
            const SizedBox(height: 12),
            Text(
              'No items found for this DO.',
              style: TextStyle(color: colors.muted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: colors.accent,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grouped.length,
        itemBuilder: (context, index) {
          final group = _grouped[index];
          return _buildProductCard(context, group);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> group) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final productName = group['ProductName'] ?? '-';
    final productCode = group['ProductCode'];
    final serials = group['Serials'] as List<Map<String, dynamic>>? ?? [];
    final items = group['Items'] as List<Map<String, dynamic>>? ?? [];

    final batches = items
        .map((i) => i['BatchNumber']?.toString() ?? '-')
        .toSet();
    final batchDisplay = batches.length == 1 ? batches.first : 'Multiple';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.text,
                        ),
                      ),
                      if (productCode != null)
                        Text(
                          'Code: $productCode',
                          style: TextStyle(fontSize: 12, color: colors.muted),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${serials.isEmpty ? items.fold<int>(0, (s, i) => s + (int.tryParse('${i['QuantityReceived'] ?? 0}') ?? 0)) : serials.length} serial(s)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Serial Number', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Batch', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Expiry', style: _tableHeaderStyle(context)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: _tableHeaderStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),

          // Serials rows
          if (serials.isNotEmpty)
            ...serials.asMap().entries.map((entry) {
              final i = entry.key;
              final serial = entry.value;
              final status = serial['current_status'] ?? 'Unknown';
              return Container(
                color: i.isEven ? colors.surface : colors.panelSoft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        serial['serial_number'] ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.text,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        batchDisplay,
                        style: TextStyle(fontSize: 13, color: colors.text),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '-',
                        style: TextStyle(fontSize: 13, color: colors.text),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusBgColor(status, isDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.statusColor(status),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Batch: $batchDisplay • Qty: ${items.fold<int>(0, (s, i) => s + (int.tryParse('${i['received_qty'] ?? 0}') ?? 0))}',
                style: TextStyle(color: colors.muted),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: colors.muted,
      letterSpacing: 0.3,
    );
  }
}
