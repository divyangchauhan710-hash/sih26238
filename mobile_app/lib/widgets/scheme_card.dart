import 'package:flutter/material.dart';
import '../models/scheme.dart';

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DISBURSED':
        return Colors.green;
      case 'SANCTIONED':
        return Colors.blue;
      case 'UNDER_VERIFICATION':
      case 'SUBMITTED':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'DISBURSED':
        return 'Disbursed via DBT';
      case 'SANCTIONED':
        return 'Sanctioned';
      case 'UNDER_VERIFICATION':
        return 'Under Verification';
      case 'SUBMITTED':
        return 'Submitted';
      case 'REJECTED':
        return 'Rejected / Clarification';
      default:
        return 'Not Applied';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(scheme.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    scheme.schemeCode,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _formatStatus(scheme.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scheme.schemeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Max Benefit: ₹${scheme.maxAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const Spacer(),
                Text(
                  'AY ${scheme.academicYear}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (scheme.hasApplied)
                  ElevatedButton.icon(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('View Status Timeline'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Apply Now'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
