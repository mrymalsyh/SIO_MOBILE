import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

/// Stock-Out Detail Screen
class StockOutDetailScreen extends StatefulWidget {
  final int stockOutId;
  final String consignmentNumber;

  const StockOutDetailScreen({
    super.key,
    required this.stockOutId,
    required this.consignmentNumber,
  });

  @override
  State<StockOutDetailScreen> createState() => _StockOutDetailScreenState();
}

class _StockOutDetailScreenState extends State<StockOutDetailScreen> {
  final _api = ApiService();
  final _lotCtrl = TextEditingController();

  static const _primaryColor = Color(0xFF4F46E5);
  static const _successColor = Color(0xFF22C55E);
  static const _dangerColor = Color(0xFFEF4444);

  bool _loading = true;
  bool _isAdmin = false;
  bool _addingLot = false;
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _details = [];

  @override
  void initState() {
    super.initState();
    _load();
    _checkRole();
  }

  @override
  void dispose() {
    _lotCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    setState(() => _isAdmin = role.toLowerCase() == 'admin');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _api.getStockOutDetail(
      context,
      stockOutId: widget.stockOutId,
    );
    if (result != null) {
      setState(() {
        _data = result;
        _details =
            (result['details'] as List?)
                ?.map((d) => Map<String, dynamic>.from(d))
                .toList() ??
            [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String get _status => _data['Status']?.toString() ?? 'Draft';
  bool get _isDraft => _status.toLowerCase() == 'draft';

  Color get _statusColor {
    switch (_status.toLowerCase()) {
      case 'supplied':
        return _successColor;
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'draft':
        return Colors.grey;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Future<void> _addLot() async {
    final lotNumber = _lotCtrl.text.trim();
    if (lotNumber.isEmpty) {
      _showSnack('Please enter a lot number.');
      return;
    }

    setState(() => _addingLot = true);
    final success = await _api.addLotToStockOut(
      context,
      stockOutId: widget.stockOutId,
      lotNumber: lotNumber,
    );
    setState(() => _addingLot = false);

    if (success) {
      _lotCtrl.clear();
      _showSnack('Lot added successfully.');
      _load();
    }
  }

  Future<void> _removeLot(int detailId) async {
    final confirm = await _showConfirmDialog(
      title: 'Remove Lot',
      message: 'Remove this lot from the consignment?',
      confirmText: 'Remove',
      isDanger: true,
    );

    if (confirm == true) {
      final success = await _api.removeLotFromStockOut(
        context,
        stockOutId: widget.stockOutId,
        detailId: detailId,
      );
      if (success) {
        if (!mounted) return;
        _showSnack('Lot removed.');
        _load();
      }
    }
  }

  Future<void> _confirmStockOut() async {
    if (_details.isEmpty) {
      _showSnack('Please add at least one lot before confirming.');
      return;
    }

    final confirm = await _showConfirmDialog(
      title: 'Confirm Stock-Out',
      message:
          'This will mark ${_details.length} lot(s) as Supplied. This action cannot be undone.',
      confirmText: 'Confirm',
      isDanger: false,
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final success = await _api.confirmStockOut(
        context,
        stockOutId: widget.stockOutId,
      );
      if (success) {
        if (!mounted) return;
        _showSnack('Stock-Out confirmed successfully.');
        Navigator.pop(context, true);
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteStockOut() async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Stock-Out',
      message:
          'Delete ${widget.consignmentNumber}?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final success = await _api.deleteStockOut(
        context,
        stockOutId: widget.stockOutId,
      );
      if (success) {
        if (!mounted) return;
        _showSnack('Deleted successfully.');
        Navigator.pop(context, true);
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDanger,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isDanger ? _dangerColor : _successColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.consignmentNumber,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: _deleteStockOut,
              icon: const Icon(Icons.delete_outline),
              color: _dangerColor,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : Column(
              children: [
                _buildHeader(),
                if (_isDraft) _buildAddLotSection(),
                Expanded(child: _buildLotsList()),
              ],
            ),
      bottomNavigationBar: _isDraft && !_loading ? _buildConfirmButton() : null,
    );
  }

  Widget _buildHeader() {
    final client = _data['client'] as Map<String, dynamic>? ?? {};
    final pic = _data['pic'] as Map<String, dynamic>? ?? {};
    final checker = _data['checker'] as Map<String, dynamic>? ?? {};
    final date = _data['StockOutDate']?.toString().split('T').first ?? '-';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Date row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const Spacer(),
              Text(
                '${_details.length} lots',
                style: TextStyle(
                  fontSize: 13,
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info row
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _infoChip(Icons.business, client['ClientName'] ?? '-'),
              _infoChip(Icons.person_outline, 'PIC: ${pic['FullName'] ?? '-'}'),
              if (checker['FullName'] != null)
                _infoChip(
                  Icons.verified_user_outlined,
                  'Checker: ${checker['FullName']}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildAddLotSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _lotCtrl,
              decoration: InputDecoration(
                hintText: 'Scan or enter lot number',
                prefixIcon: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _addLot(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _addingLot ? null : _addLot,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _addingLot
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 4),
                      Text('Add'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotsList() {
    if (_details.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _isDraft
                  ? 'Add lots to this consignment.'
                  : 'No lots in this consignment.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _details.length,
        itemBuilder: (context, index) {
          final detail = _details[index];
          final lot = detail['lot'] as Map<String, dynamic>? ?? {};
          final product = lot['product'] as Map<String, dynamic>? ?? {};
          final detailId = detail['StockOutDetailID'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                lot['LotNumber'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    product['ProductName'] ?? '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Expiry: ${lot['ExpiryDate']?.toString().split('T').first ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              trailing: _isDraft
                  ? IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _dangerColor,
                      ),
                      onPressed: () => _removeLot(detailId),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _confirmStockOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: _successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 20),
              SizedBox(width: 8),
              Text(
                'Confirm Stock-Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
