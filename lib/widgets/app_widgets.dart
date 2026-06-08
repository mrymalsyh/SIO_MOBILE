import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared reusable widgets for consistent UI
class AppWidgets {
  AppWidgets._();

  /// Stat box widget used in cards
  static Widget statBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.gray500),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.label),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray900,
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge widget
  static Widget statusBadge(String status) {
    final color = AppTheme.statusColor(status);
    final bgColor = AppTheme.statusBgColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Stat chip widget (like in detail headers)
  static Widget statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Icon container (like the card header icons)
  static Widget iconBox({
    required IconData icon,
    Color? color,
    Color? bgColor,
    double size = 36,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppTheme.indigo50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: color ?? AppTheme.indigo600, size: size * 0.55),
    );
  }

  /// Section header with icon
  static Widget sectionHeader({required String title, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        children: [
          iconBox(icon: icon, size: 32),
          const SizedBox(width: 12),
          Text(title, style: AppTheme.headingSm),
        ],
      ),
    );
  }

  /// Empty state widget
  static Widget emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.gray300),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.caption),
        ],
      ),
    );
  }

  /// Loading indicator
  static Widget get loading =>
      const Center(child: CircularProgressIndicator(color: AppTheme.indigo600));

  /// Info row (icon + text)
  static Widget infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.gray500),
        const SizedBox(width: 6),
        Text(text, style: AppTheme.bodySm),
      ],
    );
  }

  /// Gradient accent bar
  static Widget get gradientBar => Container(
    height: 3,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusLg),
      ),
      gradient: LinearGradient(
        colors: [AppTheme.indigo600, Colors.purple.shade500],
      ),
    ),
  );

  /// Form label with optional required asterisk
  static Widget formLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.gray700,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppTheme.red500,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  /// Date picker button
  static Widget dateButton({
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.gray300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.gray500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? _formatDate(date) : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? AppTheme.gray900 : AppTheme.gray400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
