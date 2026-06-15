import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

/// Stock-In Create Screen matching SIO web frontend styling
class StockInCreateScreen extends StatefulWidget {
  const StockInCreateScreen({super.key});

  @override
  State<StockInCreateScreen> createState() => _StockInCreateScreenState();
}

class _StockInCreateScreenState extends State<StockInCreateScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _df = DateFormat('yyyy-MM-dd');

  // Colors matching SIO
  static const _indigo50 = Color(0xFFEEF2FF);
  static const _indigo600 = Color(0xFF4F46E5);
  static const _gray50 = Color(0xFFF9FAFB);
  static const _gray100 = Color(0xFFF3F4F6);
  static const _gray200 = Color(0xFFE5E7EB);
  static const _gray300 = Color(0xFFD1D5DB);
  static const _gray400 = Color(0xFF9CA3AF);
  static const _gray500 = Color(0xFF6B7280);
  static const _gray700 = Color(0xFF374151);
  static const _gray900 = Color(0xFF111827);
  static const _red500 = Color(0xFFEF4444);

  // Form state
  final _doNumberCtrl = TextEditingController();
  DateTime _receiveDate = DateTime.now();
  int? _selectedSupplierId;
  int? _selectedPicId;

  // Dropdown data
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _pics = [];
  bool _loadingDropdowns = true;

  // Items
  final List<_ProductItem> _items = [];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _items.add(_ProductItem());
    _loadDropdowns();
  }

  @override
  void dispose() {
    _doNumberCtrl.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingDropdowns = true);

    // Get logged-in user's ID
    final prefs = await SharedPreferences.getInstance();
    final loggedInUserId = prefs.getInt('user_id');
    debugPrint('📋 Logged in user_id from prefs: $loggedInUserId');

    final results = await Future.wait([
      _api.getSuppliers(context),
      _api.getPics(context),
    ]);

    if (!mounted) return;

    setState(() {
      _suppliers = results[0];
      _pics = results[1];

      debugPrint('📋 PICs loaded: ${_pics.length}');
      for (final p in _pics) {
        debugPrint(
          '   - PIC: ${p['FullName']} (UserID=${p['UserID']}, type=${p['UserID'].runtimeType})',
        );
      }

      // Auto-select PIC if logged-in user is in the list
      if (loggedInUserId != null && loggedInUserId > 0 && _pics.isNotEmpty) {
        for (final p in _pics) {
          final picUserId = p['UserID'];
          // Handle both int and String types from API
          final picId = picUserId is int
              ? picUserId
              : int.tryParse('$picUserId');
          debugPrint(
            '   Comparing: picId=$picId == loggedInUserId=$loggedInUserId ? ${picId == loggedInUserId}',
          );
          if (picId == loggedInUserId) {
            _selectedPicId = picId;
            debugPrint('✅ Auto-selected PIC: $_selectedPicId');
            break;
          }
        }
      }

      _loadingDropdowns = false;
    });
  }

  void _addItem() {
    setState(() => _items.add(_ProductItem()));
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  Future<void> _pickReceiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiveDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: _indigo600)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _receiveDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill in all required fields.');
      return;
    }

    if (_selectedSupplierId == null) {
      _showSnack('Please select a supplier.');
      return;
    }

    if (_selectedPicId == null) {
      _showSnack('Please select a PIC.');
      return;
    }

    // Validate items
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.productId == null) {
        _showSnack('Please select a product for Item #${i + 1}.');
        return;
      }
      if (item.batchCtrl.text.trim().isEmpty) {
        _showSnack('Please enter batch number for Item #${i + 1}.');
        return;
      }
      final qty = int.tryParse(item.qtyCtrl.text) ?? 0;
      if (qty <= 0) {
        _showSnack('Please enter valid quantity for Item #${i + 1}.');
        return;
      }
    }

    setState(() => _submitting = true);

    final items = _items
        .map(
          (item) => {
            'ProductID': item.productId,
            'BatchNumber': item.batchCtrl.text.trim().toUpperCase(),
            'QuantityReceived': int.parse(item.qtyCtrl.text),
            'ExpiryDate': item.expiryDate != null
                ? _df.format(item.expiryDate!)
                : null,
            'Remarks': item.remarksCtrl.text.trim(),
          },
        )
        .toList();

    final result = await _api.createStockIn(
      context,
      doNumber: _doNumberCtrl.text.trim(),
      supplierId: _selectedSupplierId!,
      picId: _selectedPicId!,
      receiveDate: _df.format(_receiveDate),
      items: items,
    );

    setState(() => _submitting = false);

    if (result != null) {
      if (!mounted) return;
      _showSnack('Stock-In created successfully!');
      Navigator.of(context).pop(true);
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
          icon: const Icon(Icons.close, color: _gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Stock-In Record',
          style: TextStyle(
            color: _gray900,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _indigo600,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: _indigo600,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: _loadingDropdowns
          ? const Center(child: CircularProgressIndicator(color: _indigo600))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header section
                  _buildSectionCard(
                    title: 'Header Information',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _doNumberCtrl,
                          label: 'DO Number',
                          hint: 'e.g. DO-001',
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDateField(
                          label: 'Receive Date',
                          value: _receiveDate,
                          onTap: _pickReceiveDate,
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Supplier',
                          value: _selectedSupplierId,
                          items: _suppliers
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s['SupplierID'] as int,
                                  child: Text(s['SupplierName'] ?? '-'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedSupplierId = v;
                              for (var item in _items) {
                                item.productId = null;
                                item.productName = null;
                                item.searchCtrl.clear();
                              }
                            });
                          },
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'PIC',
                          value: _selectedPicId,
                          items: _pics
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['UserID'] as int,
                                  child: Text(p['FullName'] ?? '-'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPicId = v),
                          required: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products (${_items.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _gray900,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Product'),
                        style: TextButton.styleFrom(
                          foregroundColor: _indigo600,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildItemCard(index, item);
                  }),

                  const SizedBox(height: 100), // Space for save button
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gray100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _indigo50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, size: 18, color: _indigo600),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _gray900,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _gray900),
          decoration: _inputDecoration(hint),
          validator: required
              ? (v) => v?.trim().isEmpty == true ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gray300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(value),
                    style: const TextStyle(fontSize: 14, color: _gray900),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: _gray500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gray300),
          ),
          child: DropdownButtonFormField<int>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _gray900),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintText: 'Select ${label.toLowerCase()}...',
              hintStyle: TextStyle(color: _gray400, fontSize: 14),
            ),
            validator: required ? (v) => v == null ? 'Required' : null : null,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _gray700,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: _red500, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _gray400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _indigo600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _red500),
      ),
    );
  }

  Widget _buildItemCard(int index, _ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gray200),
      ),
      child: Column(
        children: [
          // Item header
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _indigo50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: _indigo600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Item #${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gray900,
                      ),
                    ),
                  ],
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: _red500, size: 20),
                    onPressed: () => _removeItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Product search
                _ProductSearchField(
                  controller: item.searchCtrl,
                  selectedProduct: item.productName,
                  supplierId: _selectedSupplierId,
                  onSelected: (id, name) {
                    setState(() {
                      item.productId = id;
                      item.productName = name;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Batch & Quantity row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: item.batchCtrl,
                        label: 'Batch',
                        hint: 'Batch number',
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: item.qtyCtrl,
                        label: 'Quantity',
                        hint: '0',
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Expiry date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Expiry Date', false),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              item.expiryDate ??
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 10),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _indigo600,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => item.expiryDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gray300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.expiryDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                      ).format(item.expiryDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: item.expiryDate != null
                                      ? _gray900
                                      : _gray400,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: _gray500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Remarks
                _buildTextField(
                  controller: item.remarksCtrl,
                  label: 'Remarks',
                  hint: 'Optional notes',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  final searchCtrl = TextEditingController();
  final batchCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  int? productId;
  String? productName;
  DateTime? expiryDate;

  void dispose() {
    searchCtrl.dispose();
    batchCtrl.dispose();
    qtyCtrl.dispose();
    remarksCtrl.dispose();
  }
}

class _ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? selectedProduct;
  final int? supplierId;
  final void Function(int id, String name) onSelected;

  const _ProductSearchField({
    required this.controller,
    required this.selectedProduct,
    required this.supplierId,
    required this.onSelected,
  });

  @override
  State<_ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<_ProductSearchField> {
  static const _indigo600 = Color(0xFF4F46E5);
  static const _gray300 = Color(0xFFD1D5DB);
  static const _gray400 = Color(0xFF9CA3AF);
  static const _gray500 = Color(0xFF6B7280);
  static const _gray700 = Color(0xFF374151);
  static const _gray900 = Color(0xFF111827);
  static const _green500 = Color(0xFF22C55E);
  static const _red500 = Color(0xFFEF4444);

  final _api = ApiService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.length < 2 || widget.supplierId == null) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _loading = true);
    final results = await _api.searchProducts(
      context,
      search: query,
      supplierId: widget.supplierId,
    );
    setState(() {
      _suggestions = results.where((p) => p['Status'] == 'Active').toList();
      _showSuggestions = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Product',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _gray700,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: _red500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selectedProduct != null ? _green500 : _gray300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.supplierId != null,
                  style: const TextStyle(fontSize: 14, color: _gray900),
                  decoration: InputDecoration(
                    hintText: widget.supplierId == null
                        ? 'Select supplier first'
                        : 'Type to search...',
                    hintStyle: TextStyle(color: _gray400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _search,
                  onTap: () {
                    if (widget.controller.text.length >= 2) {
                      _search(widget.controller.text);
                    }
                  },
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _indigo600,
                    ),
                  ),
                )
              else if (widget.selectedProduct != null)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle, color: _green500, size: 20),
                ),
            ],
          ),
        ),
        if (widget.selectedProduct != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Selected: ${widget.selectedProduct}',
              style: TextStyle(color: _green500, fontSize: 12),
            ),
          ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _gray300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final product = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    product['ProductName'] ?? '-',
                    style: const TextStyle(fontSize: 14, color: _gray900),
                  ),
                  subtitle: product['RefNum'] != null
                      ? Text(
                          'Ref: ${product['RefNum']}',
                          style: TextStyle(fontSize: 12, color: _gray500),
                        )
                      : null,
                  onTap: () {
                    widget.controller.text = product['ProductName'] ?? '';
                    widget.onSelected(
                      product['ProductID'] as int,
                      product['ProductName'] ?? '-',
                    );
                    setState(() {
                      _showSuggestions = false;
                      _suggestions = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
