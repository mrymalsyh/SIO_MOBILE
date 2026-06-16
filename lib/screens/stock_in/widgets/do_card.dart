import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Simple, clean DO Card for Stock-In
class DoCard extends StatelessWidget {
  final String doNumber;
  final String supplierName;
  final int totalProducts;
  final int totalQuantity;
  final String receiveDate;
  final VoidCallback onTap;

  const DoCard({
    super.key,
    required this.doNumber,
    required this.supplierName,
    required this.totalProducts,
    required this.totalQuantity,
    required this.receiveDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      color: colors.panel,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: DO Number + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    receiveDate,
                    style: TextStyle(fontSize: 12, color: colors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Supplier
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: colors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supplierName,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStat(
                    context,
                    Icons.inventory_2_outlined,
                    'Products',
                    '$totalProducts',
                  ),
                  const SizedBox(width: 24),
                  _buildStat(context, Icons.widgets_outlined, 'Units', '$totalQuantity'),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: colors.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.accent),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 13, color: colors.muted),
        ),
      ],
    );
  }
}
