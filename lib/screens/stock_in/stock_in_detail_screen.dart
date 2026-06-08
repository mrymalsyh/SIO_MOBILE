import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/printer_service.dart';

/// Stock-In Detail Screen matching MSIC_FE web frontend styling
class StockInDetailScreen extends StatefulWidget {
  final String doNumber;
  final String supplierName;
  final String receiveDate;

  const StockInDetailScreen({
    super.key,
    required this.doNumber,
    required this.supplierName,
    required this.receiveDate,
  });

  @override
  State<StockInDetailScreen> createState() => _StockInDetailScreenState();
}

class _StockInDetailScreenState extends State<StockInDetailScreen> {
  final _api = ApiService();

  // Colors matching MSIC_FE
  static const _indigo50 = Color(0xFFEEF2FF);
  static const _indigo600 = Color(0xFF4F46E5);
  static const _indigo700 = Color(0xFF4338CA);
  static const _slate50 = Color(0xFFF8FAFC);
  static const _gray50 = Color(0xFFF9FAFB);
  static const _gray100 = Color(0xFFF3F4F6);
  static const _gray200 = Color(0xFFE5E7EB);
  static const _gray400 = Color(0xFF9CA3AF);
  static const _gray500 = Color(0xFF6B7280);
  static const _gray700 = Color(0xFF374151);
  static const _gray900 = Color(0xFF111827);

  bool _loading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _header = {};

  @override
  void initState() {
    super.initState();
    _load();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    setState(() => _isAdmin = role.toLowerCase() == 'admin');
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final detail = await _api.getStockInDetail(
      context,
      doNumber: widget.doNumber,
    );

    setState(() {
      _rows = detail;
      if (detail.isNotEmpty) {
        final first = detail.first;
        _header = {
          'DO_Number': widget.doNumber,
          'SupplierName':
              first['Supplier']?['SupplierName'] ?? widget.supplierName,
          'PIC': first['PIC']?['FullName'] ?? '-',
          'ReceiveDate': first['ReceiveDate'] ?? widget.receiveDate,
        };
      }
      _loading = false;
    });
  }

  // Group rows by product
  List<Map<String, dynamic>> get _grouped {
    final Map<int, Map<String, dynamic>> groups = {};

    for (var row in _rows) {
      final productId = row['Product']?['ProductID'] ?? row['ProductID'] ?? 0;
      final productName = row['Product']?['ProductName'] ?? '-';
      final refNum = row['Product']?['RefNum'];

      if (!groups.containsKey(productId)) {
        groups[productId] = {
          'ProductID': productId,
          'ProductName': productName,
          'RefNum': refNum,
          'Lots': <Map<String, dynamic>>[],
          'Items': <Map<String, dynamic>>[],
        };
      }

      groups[productId]!['Items'].add(row);

      final lots = row['Lots'] as List? ?? [];
      for (var lot in lots) {
        groups[productId]!['Lots'].add(Map<String, dynamic>.from(lot));
      }
    }

    return groups.values.toList();
  }

  int get _totalQty => _rows.fold<int>(
    0,
    (sum, row) => sum + (int.tryParse('${row['QuantityReceived'] ?? 0}') ?? 0),
  );

  int get _totalLots {
    int count = 0;
    for (var row in _rows) {
      final lots = row['Lots'] as List? ?? [];
      count += lots.length;
    }
    return count > 0 ? count : _totalQty;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF22C55E); // green-500
      case 'supplied':
        return const Color(0xFF3B82F6); // blue-500
      case 'returned':
        return const Color(0xFFF59E0B); // amber-500
      case 'disposed':
        return const Color(0xFFEF4444); // red-500
      case 'pending supply':
        return _indigo600;
      case 'expired':
        return const Color(0xFFF97316); // orange-500
      default:
        return _gray500;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFFDCFCE7); // green-100
      case 'supplied':
        return const Color(0xFFDBEAFE); // blue-100
      case 'returned':
        return const Color(0xFFFEF3C7); // amber-100
      case 'disposed':
        return const Color(0xFFFEE2E2); // red-100
      case 'pending supply':
        return _indigo50;
      case 'expired':
        return const Color(0xFFFFEDD5); // orange-100
      default:
        return _gray100;
    }
  }

  Future<void> _onPrint() async {
    final allLots = <Map<String, dynamic>>[];

    for (var row in _rows) {
      final productName = row['Product']?['ProductName'] ?? '-';
      final refNum = row['Product']?['RefNum'] ?? '';
      final lots = row['Lots'] as List? ?? [];

      for (var lot in lots) {
        allLots.add({
          'medicine_name': productName,
          'reference_number': refNum,
          'expiry_date': lot['ExpiryDate'] ?? '',
          'lot_number': lot['LotNumber'] ?? '',
        });
      }
    }

    if (allLots.isEmpty) {
      _showSnack('No lots available to print.');
      return;
    }

    try {
      await PrinterService.printAllLots(context, allLots);
    } catch (e) {
      _showSnack('Print failed: $e');
    }
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete DO'),
        content: Text(
          'Delete ${widget.doNumber} and all related lots?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _gray500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final success = await _api.deleteStockInDo(context, widget.doNumber);
      if (success) {
        if (!mounted) return;
        _showSnack('Deleted successfully.');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _loading = false);
      }
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
    return Scaffold(
      backgroundColor: _gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.doNumber,
          style: const TextStyle(
            color: _gray900,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onPrint,
            icon: const Icon(Icons.print_outlined),
            color: _indigo600,
            tooltip: 'Print Labels',
          ),
          if (_isAdmin)
            IconButton(
              onPressed: _onDelete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _indigo600))
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildLotsList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info row
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _headerItem(Icons.description_outlined, 'DO: ${widget.doNumber}'),
              _headerItem(
                Icons.apartment,
                _header['SupplierName'] ?? widget.supplierName,
              ),
              _headerItem(
                Icons.calendar_today_outlined,
                _header['ReceiveDate'] ?? widget.receiveDate,
              ),
              _headerItem(
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
                color: _indigo600,
                bgColor: _indigo50,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.tag,
                label: 'Lots',
                value: _totalLots.toString(),
                color: const Color(0xFF22C55E),
                bgColor: const Color(0xFFDCFCE7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _gray500),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: _gray700)),
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

  Widget _buildLotsList() {
    if (_rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: _gray400),
            const SizedBox(height: 12),
            Text(
              'No items found for this DO.',
              style: TextStyle(color: _gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _indigo600,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grouped.length,
        itemBuilder: (context, index) {
          final group = _grouped[index];
          return _buildProductCard(group);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> group) {
    final productName = group['ProductName'] ?? '-';
    final refNum = group['RefNum'];
    final lots = group['Lots'] as List<Map<String, dynamic>>? ?? [];
    final items = group['Items'] as List<Map<String, dynamic>>? ?? [];

    final batches = items
        .map((i) => i['BatchNumber']?.toString() ?? '-')
        .toSet();
    final batchDisplay = batches.length == 1 ? batches.first : 'Multiple';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gray200),
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
              color: _gray100,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _gray900,
                        ),
                      ),
                      if (refNum != null)
                        Text(
                          'Ref: $refNum',
                          style: TextStyle(fontSize: 12, color: _gray500),
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
                    color: _indigo50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lots.isEmpty ? items.fold<int>(0, (s, i) => s + (int.tryParse('${i['QuantityReceived'] ?? 0}') ?? 0)) : lots.length} lot(s)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _indigo700,
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
                  child: Text('Lot Number', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Batch', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Expiry', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: _tableHeaderStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _gray200),

          // Lots rows
          if (lots.isNotEmpty)
            ...lots.asMap().entries.map((entry) {
              final i = entry.key;
              final lot = entry.value;
              final status = lot['Status'] ?? 'Unknown';
              return Container(
                color: i.isEven ? Colors.white : _slate50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        lot['LotNumber'] ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _gray900,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        batchDisplay,
                        style: const TextStyle(fontSize: 13, color: _gray700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        lot['ExpiryDate']?.toString().split('T').first ?? '-',
                        style: const TextStyle(fontSize: 13, color: _gray700),
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
                            color: _statusBgColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(status),
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
                'Batch: $batchDisplay • Qty: ${items.fold<int>(0, (s, i) => s + (int.tryParse('${i['QuantityReceived'] ?? 0}') ?? 0))}',
                style: TextStyle(color: _gray500),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle get _tableHeaderStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _gray500,
    letterSpacing: 0.3,
  );
}
