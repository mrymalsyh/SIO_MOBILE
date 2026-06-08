import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'do_card.dart';
import '../details/do_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  bool _loading = false;

  List<Map<String, dynamic>> _raw = [];
  List<Map<String, dynamic>> _items = [];
  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
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

    final list = await _api.getStockInList(
      context,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      fromDate: _from == null ? null : _df.format(_from!),
      toDate: _to == null ? null : _df.format(_to!),
    );

    _raw = list;
    _applyFilters();
    setState(() => _loading = false);
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final fromStr = _from != null ? _df.format(_from!) : null;
    final toStr = _to != null ? _df.format(_to!) : null;

    bool inRange(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return true;
      if (fromStr != null && dateStr.compareTo(fromStr) < 0) return false;
      if (toStr != null && dateStr.compareTo(toStr) > 0) return false;
      return true;
    }

    final filtered = _raw.where((m) {
      final doNo = (m['DO_Number'] ?? '').toString();
      final supplier = (m['SupplierName'] ?? '').toString();
      final date = (m['ReceiveDate'] ?? '').toString();
      final textMatch =
          q.isEmpty ||
          doNo.toLowerCase().contains(q) ||
          supplier.toLowerCase().contains(q);
      return textMatch && inRange(date);
    }).toList();

    setState(() => _items = filtered);
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
      _applyFilters();
    }
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _from = null;
    _to = null;
    _applyFilters();
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by DO number or supplier',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearFilters,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _from == null ? 'From Date' : _df.format(_from!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_to == null ? 'To Date' : _df.format(_to!)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear all filters',
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _items.isEmpty) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_items.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No stock-in records found.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final it = _items[index];
            final code = it['DO_Number']?.toString() ?? '-';
            final supplier = it['SupplierName']?.toString() ?? '-';
            final products = it['TotalProducts'] is int
                ? it['TotalProducts']
                : int.tryParse('${it['TotalProducts'] ?? 0}') ?? 0;
            final date = it['ReceiveDate']?.toString() ?? '-';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DoCard(
                code: code,
                supplier: supplier,
                products: products,
                date: date,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoDetailScreen(doId: code),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Stock-In List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [_buildFilters(), const SizedBox(height: 4), _buildList()],
      ),
    );
  }
}
