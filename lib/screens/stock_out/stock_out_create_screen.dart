import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'stock_out_detail_screen.dart';

/// Stock-Out Create Screen matching MSIC_FE web frontend styling
class StockOutCreateScreen extends StatefulWidget {
  const StockOutCreateScreen({super.key});

  @override
  State<StockOutCreateScreen> createState() => _StockOutCreateScreenState();
}

class _StockOutCreateScreenState extends State<StockOutCreateScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _df = DateFormat('yyyy-MM-dd');

  // Colors matching MSIC_FE
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
  final _consignmentCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _stockOutDate = DateTime.now();
  int? _selectedClientId;
  int? _selectedPicId;
  int? _selectedCheckerId;

  // Dropdown data
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _pics = [];
  bool _loadingDropdowns = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _consignmentCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingDropdowns = true);

    // Get logged-in user's ID
    final prefs = await SharedPreferences.getInstance();
    final loggedInUserId = prefs.getInt('user_id');

    final results = await Future.wait([
      _api.getClients(context),
      _api.getPics(context),
    ]);

    if (!mounted) return;

    setState(() {
      _clients = results[0];
      _pics = results[1];

      // Auto-select PIC if logged-in user is in the list
      if (loggedInUserId != null && loggedInUserId > 0 && _pics.isNotEmpty) {
        for (final p in _pics) {
          final picUserId = p['UserID'];
          // Handle both int and String types from API
          final picId = picUserId is int
              ? picUserId
              : int.tryParse('$picUserId');
          if (picId == loggedInUserId) {
            _selectedPicId = picId;
            break;
          }
        }
      }

      _loadingDropdowns = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _stockOutDate,
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
      setState(() => _stockOutDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill in all required fields.');
      return;
    }

    if (_selectedClientId == null) {
      _showSnack('Please select a client.');
      return;
    }

    if (_selectedPicId == null) {
      _showSnack('Please select a PIC.');
      return;
    }

    setState(() => _submitting = true);

    final result = await _api.createStockOut(
      context,
      consignmentNumber: _consignmentCtrl.text.trim(),
      clientId: _selectedClientId!,
      picId: _selectedPicId!,
      checkerId: _selectedCheckerId,
      stockOutDate: _df.format(_stockOutDate),
      remarks: _remarksCtrl.text.trim(),
    );

    setState(() => _submitting = false);

    if (result != null) {
      final stockOutId = result['StockOutID'];
      if (!mounted) return;
      _showSnack('Stock-Out created! Add lots now.');

      if (stockOutId != null) {
        // Navigate to detail to add lots
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StockOutDetailScreen(
              stockOutId: stockOutId is int
                  ? stockOutId
                  : int.parse('$stockOutId'),
              consignmentNumber: _consignmentCtrl.text.trim(),
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
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
          icon: const Icon(Icons.close, color: _gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Stock-Out',
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
                  _buildSectionCard(
                    title: 'Consignment Details',
                    icon: Icons.local_shipping_outlined,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _consignmentCtrl,
                          label: 'Consignment Number',
                          hint: 'e.g. CN-001',
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDateField(
                          label: 'Stock-Out Date',
                          value: _stockOutDate,
                          onTap: _pickDate,
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Client',
                          value: _selectedClientId,
                          items: _clients
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['ClientID'] as int?,
                                  child: Text(c['ClientName'] ?? '-'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedClientId = v),
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'PIC',
                          value: _selectedPicId,
                          items: _pics
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['UserID'] as int?,
                                  child: Text(p['FullName'] ?? '-'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedPicId = v),
                          required: true,
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: 'Checker',
                          value: _selectedCheckerId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('None'),
                            ),
                            ..._pics.map(
                              (p) => DropdownMenuItem(
                                value: p['UserID'] as int?,
                                child: Text(p['FullName'] ?? '-'),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedCheckerId = v),
                          required: false,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _remarksCtrl,
                          label: 'Remarks',
                          hint: 'Optional notes',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _indigo50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _indigo600.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _indigo600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After saving, you\'ll be able to add lots by scanning.',
                            style: TextStyle(fontSize: 13, color: _indigo600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
                  child: Icon(icon, size: 18, color: _indigo600),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
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
    required List<DropdownMenuItem<int?>> items,
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
          child: DropdownButtonFormField<int?>(
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
}
