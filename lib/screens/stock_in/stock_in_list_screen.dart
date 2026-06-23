import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/do_card.dart';
import 'stock_in_detail_screen.dart';
import '../../main.dart';

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
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Stock-In',
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              MyApp.of(context).toggleTheme();
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode, 
              color: colors.text
            ),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, color: colors.muted),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            color: colors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    hintText: 'Search Stock In Number',
                    hintStyle: TextStyle(color: colors.muted),
                    prefixIcon: Icon(Icons.search, size: 20, color: colors.muted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: colors.muted),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.line),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),

                // Date filters row
                Row(
                  children: [
                    Expanded(child: _buildDateChip(context, _from, 'From', true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDateChip(context, _to, 'To', false)),
                    const SizedBox(width: 8),
                    _buildClearButton(context),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading && _groups.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: colors.accent),
                  )
                : _groups.isEmpty
                ? _buildEmptyState(context)
                : RefreshIndicator(
                    color: colors.accent,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: _groups.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _groups.length) return _buildPagination(context);
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
    );
  }

  Widget _buildDateChip(BuildContext context, DateTime? date, String label, bool isFrom) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasValue = date != null;
    return InkWell(
      onTap: () => _pickDate(isFrom),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: colors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? DateFormat('dd MMM').format(date) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue ? colors.text : colors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: _clearFilters,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.panel,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.filter_alt_off_outlined,
          size: 20,
          color: colors.muted,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: colors.muted),
          const SizedBox(height: 12),
          Text(
            'No stock-ins found.',
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    if (_lastPage <= 1) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationButton(context, Icons.chevron_left, _page > 1, () {
            _page--;
            _load();
          }),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_page of $_lastPage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.text,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _paginationButton(context, Icons.chevron_right, _page < _lastPage, () {
            _page++;
            _load();
          }),
        ],
      ),
    );
  }

  Widget _paginationButton(BuildContext context, IconData icon, bool enabled, VoidCallback onTap) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? colors.surface : colors.panelSoft,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? colors.text : colors.muted,
        ),
      ),
    );
  }
}
