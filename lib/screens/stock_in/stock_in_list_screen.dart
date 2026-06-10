import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'widgets/do_card.dart';
import 'stock_in_detail_screen.dart';
import 'stock_in_create_screen.dart';

/// Stock-In List Screen
class StockInListScreen extends StatefulWidget {
  const StockInListScreen({super.key});

  @override
  State<StockInListScreen> createState() => _StockInListScreenState();
}

class _StockInListScreenState extends State<StockInListScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  final _df = DateFormat('yyyy-MM-dd');

  static const _primaryColor = Color(0xFF4F46E5);

  DateTime? _from;
  DateTime? _to;
  bool _loading = false;
  int _page = 1;
  int _lastPage = 1;

  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);

    final result = await _api.getStockInListFull(
      context,
      page: _page,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      fromDate: _from == null ? null : _df.format(_from!),
      toDate: _to == null ? null : _df.format(_to!),
    );

    final list = result['data'] as List? ?? [];
    final formatted = list.map((item) {
      final itemMap = Map<String, dynamic>.from(item);
      final lines = itemMap['lines'] as List? ?? [];
      return {
        'id': itemMap['id'],
        'DO_Number': itemMap['stock_in_number'],
        'supplier': {'SupplierName': itemMap['supplier_name']},
        'ReceiveDate': itemMap['stock_in_date'],
        'TotalProducts': lines.length,
        'TotalQuantity': lines.fold<int>(
          0,
          (sum, it) => sum + (int.tryParse('${it['received_qty'] ?? 0}') ?? 0),
        ),
      };
    }).toList();

    setState(() {
      _groups = formatted;
      _page = result['current_page'] ?? 1;
      _lastPage = result['last_page'] ?? 1;
      _loading = false;
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDate: isFrom ? _from ?? now : _to ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
      _page = 1;
      _load();
    }
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _from = null;
    _to = null;
    _page = 1;
    _load();
  }

  void _onSearch() {
    _page = 1;
    _load();
  }

  void _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StockInCreateScreen()),
    );
    if (result == true) {
      _page = 1;
      _load();
    }
  }

  void _openDetail(Map<String, dynamic> group) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockInDetailScreen(
          stockInId: group['id'] ?? 0,
          stockInNumber: group['DO_Number'] ?? '',
          supplierName: group['supplier']?['SupplierName'] ?? '-',
          receiveDate: group['ReceiveDate'] ?? '-',
        ),
      ),
    );
    if (result == true) {
      _page = 1;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Stock-In',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade600),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search DO Number',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),

                // Date filters row
                Row(
                  children: [
                    Expanded(child: _buildDateChip(_from, 'From', true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDateChip(_to, 'To', false)),
                    const SizedBox(width: 8),
                    _buildClearButton(),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading && _groups.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _groups.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: _groups.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _groups.length) return _buildPagination();
                        final group = _groups[index];
                        return DoCard(
                          doNumber: group['DO_Number']?.toString() ?? '-',
                          supplierName:
                              group['supplier']?['SupplierName']?.toString() ??
                              '-',
                          totalProducts: group['TotalProducts'] ?? 0,
                          totalQuantity: group['TotalQuantity'] ?? 0,
                          receiveDate:
                              group['ReceiveDate']
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              '-',
                          onTap: () => _openDetail(group),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 140,
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Stock-In',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime? date, String label, bool isFrom) {
    final hasValue = date != null;
    return InkWell(
      onTap: () => _pickDate(isFrom),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? DateFormat('dd MMM').format(date) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue ? Colors.grey.shade800 : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return InkWell(
      onTap: _clearFilters,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.filter_alt_off_outlined,
          size: 20,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No stock-ins found.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationButton(Icons.chevron_left, _page > 1, () {
            _page--;
            _load();
          }),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_page of $_lastPage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _paginationButton(Icons.chevron_right, _page < _lastPage, () {
            _page++;
            _load();
          }),
        ],
      ),
    );
  }

  Widget _paginationButton(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
