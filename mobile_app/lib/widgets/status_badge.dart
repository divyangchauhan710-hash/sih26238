import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.fontSize = 11.0,
  }) : super(key: key);

  factory StatusBadge.fromStatus(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);
    IconData? ic = Icons.info_outline;
    String displayLabel = status.replaceAll('_', ' ');

    switch (status.toUpperCase()) {
      case 'VERIFIED':
      case 'DISBURSED':
      case 'SUCCESS':
      case 'APPROVED':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        ic = Icons.check_circle;
        break;
      case 'SUBMITTED':
      case 'UNDER_VERIFICATION':
      case 'PENDING':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        ic = Icons.hourglass_top;
        break;
      case 'MANUAL_REVIEW':
      case 'MISMATCH':
      case 'WARNING':
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFF9A3412);
        ic = Icons.warning_amber_rounded;
        break;
      case 'REJECTED':
      case 'FAILED':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        ic = Icons.cancel;
        break;
    }

    return StatusBadge(
      label: displayLabel,
      backgroundColor: bg,
      textColor: text,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
