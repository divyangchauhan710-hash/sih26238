import 'package:flutter/material.dart';
import '../models/application.dart';

class TimelineWidget extends StatelessWidget {
  final ApplicationDetail application;

  const TimelineWidget({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 4 major pipeline stages: 1. Submitted, 2. Verification, 3. Sanctioned, 4. Disbursed
    final bool isSubmitted = application.status != 'DRAFT';
    final bool isVerified = application.verifications.isNotEmpty &&
        application.verifications.every((v) => v.status == 'VERIFIED');
    final bool isSanctioned = application.sanctionedAmount > 0;
    final bool isDisbursed = application.disbursedAmount > 0;

    return Column(
      children: [
        _buildTimelineStep(
          title: 'Stage 1: Application Submitted',
          subtitle: application.submittedAt != null
              ? 'Submitted on ${application.submittedAt!.substring(0, 10)}'
              : 'Draft application ready',
          isDone: isSubmitted,
          isCurrent: application.status == 'SUBMITTED',
          icon: Icons.assignment_turned_in,
        ),
        _buildLine(isDone: isSubmitted),
        _buildVerificationStageStep(isDone: isVerified, isCurrent: application.status == 'UNDER_VERIFICATION'),
        _buildLine(isDone: isVerified),
        _buildTimelineStep(
          title: 'Stage 3: Amount Sanctioned',
          subtitle: isSanctioned
              ? 'Sanctioned Amount: ₹${application.sanctionedAmount.toStringAsFixed(0)}'
              : 'Pending verification completion',
          isDone: isSanctioned,
          isCurrent: application.status == 'SANCTIONED',
          icon: Icons.verified_user,
        ),
        _buildLine(isDone: isSanctioned),
        _buildTimelineStep(
          title: 'Stage 4: DBT Fund Disbursed',
          subtitle: isDisbursed
              ? 'Disbursed Amount: ₹${application.disbursedAmount.toStringAsFixed(0)}\nRef: ${application.dbtRef}'
              : 'Awaiting PFMS Direct Benefit Transfer credit',
          isDone: isDisbursed,
          isCurrent: application.status == 'DISBURSED',
          icon: Icons.account_balance,
        ),
      ],
    );
  }

  Widget _buildLine({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.only(left: 23),
      height: 24,
      width: 3,
      color: isDone ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required IconData icon,
  }) {
    final color = isDone ? Colors.green : (isCurrent ? Colors.orange : Colors.grey);

    return Row(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.green.shade900 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildVerificationStageStep({required bool isDone, required bool isCurrent}) {
    final color = isDone ? Colors.green : (isCurrent ? Colors.orange : Colors.grey);

    return Row(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.rule, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text(
                  'Stage 2: Multi-Agency Verifications',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (application.verifications.isEmpty)
                  const Text('No verifications generated yet.', style: TextStyle(fontSize: 13, color: Colors.grey))
                else
                  Column(
                    children: application.verifications.map((chk) {
                      IconData chkIcon = Icons.hourglass_top;
                      Color chkColor = Colors.orange;

                      if (chk.status == 'VERIFIED') {
                        chkIcon = Icons.check_circle;
                        chkColor = Colors.green;
                      } else if (chk.status == 'MISMATCH' || chk.status == 'MANUAL_REVIEW') {
                        chkIcon = Icons.warning_amber_rounded;
                        chkColor = Colors.red;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(chkIcon, color: chkColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${chk.checkType} (${chk.sourceSystem})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: chkColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                chk.status,
                                style: TextStyle(color: chkColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
