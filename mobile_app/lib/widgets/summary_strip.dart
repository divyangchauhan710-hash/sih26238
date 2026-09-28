import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Direct Benefit Transfer (DBT)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MoTA Verified',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Disbursed',
                '₹${totalDisbursed.toStringAsFixed(0)}',
                Colors.lightGreenAccent,
              ),
              Container(height: 36, width: 1, color: Colors.white30),
              _buildSummaryItem(
                'Total Sanctioned',
                '₹${totalSanctioned.toStringAsFixed(0)}',
                Colors.amberAccent,
              ),
              Container(height: 36, width: 1, color: Colors.white30),
              _buildSummaryItem(
                'Pending Checks',
                '$pendingVerifications',
                Colors.orangeAccent,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
