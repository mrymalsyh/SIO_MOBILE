import 'package:flutter/material.dart';

/// Simple, clean Consignment Card for Stock-Out
class ConsignmentCard extends StatelessWidget {
  final String consignmentNumber;
  final String clientName;
  final int totalProducts;
  final int totalQuantity;
  final String stockOutDate;
  final String status;
  final String? remarks;
  final VoidCallback onTap;

  const ConsignmentCard({
    super.key,
    required this.consignmentNumber,
    required this.clientName,
    required this.totalProducts,
    required this.totalQuantity,
    required this.stockOutDate,
    required this.status,
    this.remarks,
    required this.onTap,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'supplied':
        return const Color(0xFF22C55E);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'draft':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Consignment Number + Status + Date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      consignmentNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Text(
                stockOutDate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),

              // Client
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
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
                    Icons.inventory_2_outlined,
                    'Products',
                    '$totalProducts',
                  ),
                  const SizedBox(width: 24),
                  _buildStat(Icons.widgets_outlined, 'Units', '$totalQuantity'),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
