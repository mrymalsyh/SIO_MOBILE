import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/printer_service.dart';

class DoDetailScreen extends StatefulWidget {
  final String doId;
  const DoDetailScreen({super.key, required this.doId});

  @override
  State<DoDetailScreen> createState() => _DoDetailScreenState();
}

class _DoDetailScreenState extends State<DoDetailScreen> {
  final _api = ApiService();

  bool _loading = true;
  Map<String, dynamic> _header = {};
  List<Map<String, dynamic>> _lots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDoLots(context, doId: widget.doId);
    // Debug: print('🔍 API Response: $res');

    setState(() {
      _header = Map<String, dynamic>.from(res['header'] ?? {});
      _lots =
          (res['lots'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _loading = false;
    });
  }

  Widget _buildHeader() {
    final code = _header['DO_Number']?.toString() ?? '-';
    final supplier = _header['SupplierName']?.toString() ?? '-';
    final date = _header['ReceiveDate']?.toString() ?? '-';
    final totalLots =
        _header['TotalLots']?.toString() ?? _lots.length.toString();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _iconText(Icons.sell, 'DO: $code'),
                _iconText(Icons.business, supplier),
                _iconText(Icons.calendar_today, date),
              ],
            ),
            const SizedBox(height: 8),
            _iconText(Icons.list_alt, 'Total Lots: $totalLots'),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildGroupedLots() {
    if (_loading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_lots.isEmpty) {
      return const Expanded(child: Center(child: Text('No lots for this DO.')));
    }

    // ✅ Group by product + ref
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var lot in _lots) {
      final key = '${lot['ProductName'] ?? '-'}|${lot['RefNum'] ?? '-'}';
      grouped.putIfAbsent(key, () => []).add(lot);
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: grouped.entries.map((entry) {
            final parts = entry.key.split('|');
            final product = parts[0];
            final ref = parts[1] != '-' ? parts[1] : '';
            final lots = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name + ref + lot count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: product,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            children: [
                              if (ref.isNotEmpty)
                                TextSpan(
                                  text: '  Ref: $ref',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${lots.length} lot(s)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    // Table Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Lot Number',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Expiry',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Table Rows
                    Column(
                      children: lots.map((lot) {
                        final lotNum = lot['LotNumber'] ?? '-';
                        final expiry = lot['ExpiryDate'] ?? '-';
                        final status = lot['Status'] ?? 'Unknown';

                        Color color;
                        switch (status.toLowerCase()) {
                          case 'available':
                            color = Colors.green;
                            break;
                          case 'disposed':
                            color = Colors.red;
                            break;
                          case 'pending':
                            color = Colors.orange;
                            break;
                          default:
                            color = Colors.grey;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(lotNum)),
                              Expanded(flex: 2, child: Text(expiry)),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onPrint() async {
    if (_lots.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No lots to print.')));
      return;
    }

    try {
      // Convert _lots to the expected structure
      final formattedLots = _lots.map((lot) {
        return {
          'medicine_name': lot['ProductName'] ?? '',
          'reference_number': lot['RefNum'] ?? '',
          'expiry_date': lot['ExpiryDate'] ?? '',
          'lot_number': lot['LotNumber'] ?? '',
        };
      }).toList();

      await PrinterService.printAllLots(context, formattedLots);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Print failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doId),
        actions: [
          IconButton(
            onPressed: _onPrint,
            icon: const Icon(Icons.print),
            tooltip: 'Print',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildGroupedLots(),
        ],
      ),
    );
  }
}
