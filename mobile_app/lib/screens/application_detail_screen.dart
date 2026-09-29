import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/timeline_widget.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final ApplicationDetail application;

  const ApplicationDetailScreen({Key? key, required this.application}) : super(key: key);

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool isTriggering = false;

  Future<void> _handleTriggerVerification(String checkId) async {
    setState(() => isTriggering = true);
    final state = Provider.of<AppState>(context, listen: false);
    await state.triggerVerificationCheck(checkId);
    setState(() => isTriggering = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification check executed live via Government Adapter!'),
          backgroundColor: AppTheme.infoBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final updatedApp = state.applications.firstWhere(
      (a) => a.id == widget.application.id,
      orElse: () => widget.application,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: Text(updatedApp.schemeName, style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application Card Header
            Container(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Application Status',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ),
                        StatusBadge.fromStatus(updatedApp.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Application ID: ${updatedApp.id}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text('Academic Year: ${updatedApp.academicYear}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    if (updatedApp.dbtRef != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PFMS-DBT Ref: ${updatedApp.dbtRef}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Multi-Agency Automated Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),

            // Timeline Widget
            TimelineWidget(application: updatedApp),

            const SizedBox(height: 24),

            // Interactive Live Verification Trigger Section
            Container(
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: AppTheme.warningOrange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Live Adapter Verification Test',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.warningOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any check below to manually trigger real-time multi-agency verification.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (isTriggering)
                      const Center(child: CircularProgressIndicator(color: AppTheme.warningOrange))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: updatedApp.verifications.map((v) {
                          return OutlinedButton.icon(
                            onPressed: () => _handleTriggerVerification(v.id),
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: Text('Verify ${v.checkType}'),
                          );
                        }).toList(),
                      )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
