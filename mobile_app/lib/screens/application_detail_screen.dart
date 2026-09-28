import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application.dart';
import '../providers/app_state.dart';
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
          content: Text('Verification check triggered via Government Adapter.'),
          backgroundColor: Colors.blue,
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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text(updatedApp.schemeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // Application Card Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Application Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AY ${updatedApp.academicYear}',
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 20),
                    Text('App ID: ${updatedApp.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Current Status: ${updatedApp.status}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'End-to-End Application Timeline',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Timeline Widget
            TimelineWidget(application: updatedApp),

            const SizedBox(height: 24),

            // Interactive Verification Trigger Section (Demonstrating live orchestrator calls to judges)
            Card(
              elevation: 1,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bolt, color: Colors.amber, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Live Adapter Orchestrator Test (SIH Demo)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any check below to manually trigger the Python microservice adapter for real-time response.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    if (isTriggering)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 8,
                        children: updatedApp.verifications.map((v) {
                          return OutlinedButton.icon(
                            onPressed: () => _handleTriggerVerification(v.id),
                            icon: const Icon(Icons.refresh, size: 14),
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
