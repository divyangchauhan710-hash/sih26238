import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryStrip extends StatelessWidget {
  final double totalSanctioned;
  final double totalDisbursed;
  final int pendingVerifications;

  const SummaryStrip({
    Key? key,
    required this.totalSanctioned,
    required this.totalDisbursed,
    required this.pendingVerifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Direct Benefit Transfer (DBT) Overview',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Aadhaar Seeded',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Sanctioned',
                      '₹${totalSanctioned.toStringAsFixed(0)}',
                      Colors.white,
                    ),
                  ),
                  Container(height: 36, width: 1, color: Colors.white24),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Disbursed',
                      '₹${totalDisbursed.toStringAsFixed(0)}',
                      const Color(0xFF86EFAC), // Soft green
                    ),
                  ),
                  Container(height: 36, width: 1, color: Colors.white24),
                  Expanded(
                    child: _buildSummaryItem(
                      'Pending Checks',
                      '$pendingVerifications',
                      pendingVerifications > 0 ? const Color(0xFFFDBA74) : Colors.white, // Soft orange if pending
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
