import 'package:flutter/material.dart';
import '../models/scheme.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class SchemeCard extends StatelessWidget {
  final SchemeOverview scheme;
  final VoidCallback onApply;
  final VoidCallback onViewDetails;

  const SchemeCard({
    Key? key,
    required this.scheme,
    required this.onApply,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canApply = !scheme.hasApplied;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scheme.schemeCode,
                    style: const TextStyle(
                      color: AppTheme.infoBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                StatusBadge.fromStatus(scheme.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              scheme.schemeName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 14, color: AppTheme.accentTeal),
                const SizedBox(width: 4),
                const Text(
                  'Max Benefit: ',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  '₹${scheme.maxAmount.toStringAsFixed(0)} / Year',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (scheme.hasApplied)
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.timeline_rounded, size: 16),
                    label: const Text('View Status Timeline'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: canApply ? onApply : null,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Apply Now'),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
