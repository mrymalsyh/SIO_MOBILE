import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared reusable widgets for consistent UI
class AppWidgets {
  AppWidgets._();

  /// Stat box widget used in cards
  static Widget statBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.panelSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.muted),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.label.copyWith(color: colors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge widget
  static Widget statusBadge(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.statusColor(status);
    final bgColor = AppTheme.statusBgColor(status, isDark);

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
  static Widget statChip(
    BuildContext context, {
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
  static Widget iconBox(
    BuildContext context, {
    required IconData icon,
    Color? color,
    Color? bgColor,
    double size = 36,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? colors.panelSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: color ?? colors.text, size: size * 0.55),
    );
  }

  /// Section header with icon
  static Widget sectionHeader(BuildContext context, {required String title, required IconData icon}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        children: [
          iconBox(context, icon: icon, size: 32),
          const SizedBox(width: 12),
          Text(title, style: AppTheme.headingSm.copyWith(color: colors.text)),
        ],
      ),
    );
  }

  /// Empty state widget
  static Widget emptyState(BuildContext context, {required IconData icon, required String message}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colors.muted),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.caption.copyWith(color: colors.muted)),
        ],
      ),
    );
  }

  /// Loading indicator
  static Widget loading(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(child: CircularProgressIndicator(color: colors.accent));
  }

  /// Info row (icon + text)
  static Widget infoRow(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.muted),
        const SizedBox(width: 6),
        Text(text, style: AppTheme.bodySm.copyWith(color: colors.muted)),
      ],
    );
  }

  /// Gradient accent bar
  static Widget gradientBar(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
        gradient: LinearGradient(
          colors: [colors.text, colors.muted],
        ),
      ),
    );
  }

  /// Form label with optional required asterisk
  static Widget formLabel(BuildContext context, String label, {bool required = false}) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.text,
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
  static Widget dateButton(
    BuildContext context, {
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final hasValue = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: colors.line),
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
                hasValue ? _formatDate(date) : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? colors.text : colors.muted,
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
