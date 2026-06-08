import 'package:flutter/material.dart';

class DoCard extends StatelessWidget {
  final String code;
  final String supplier;
  final int products;
  final int? units; // optional: for “x products • y units”
  final String date;
  final VoidCallback onTap;

  const DoCard({
    super.key,
    required this.code,
    required this.supplier,
    required this.products,
    required this.date,
    required this.onTap,
    this.units,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header row ---
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          code,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Stock-In DO',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- Supplier name ---
              Row(
                children: [
                  const Icon(Icons.apartment, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      supplier,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // --- Products & units ---
              Row(
                children: [
                  const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    units == null
                        ? '$products products'
                        : '$products product${products > 1 ? 's' : ''} • $units units',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // --- Date ---
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Purple accent line ---
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
