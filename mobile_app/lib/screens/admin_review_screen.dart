import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({Key? key}) : super(key: key);

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final TextEditingController _notesController = TextEditingController();

  void _handleDecision(String queueId, String status) async {
    final state = Provider.of<AppState>(context, listen: false);
    final notes = _notesController.text.trim().isEmpty
        ? 'Verified by District Officer during SIH hackathon review'
        : _notesController.text.trim();

    final success = await state.resolveReview(queueId, status, notes);
    _notesController.clear();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as $status successfully! Application updated.'),
            backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update review decision')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final queue = state.reviewQueue;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        foregroundColor: Colors.white,
        title: const Text('Verifier Manual Review Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.loadReviewQueue(),
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : queue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 12),
                      Text('No pending mismatches in queue!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final item = queue[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Text(
                                    'MISMATCH: ${item.checkType}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Text(
                                  'Confidence: ${(item.confidenceScore * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Beneficiary: ${item.studentName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Scheme: ${item.schemeName}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            Text('Source System: ${item.sourceSystem}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Divider(height: 20),
                            Text(
                              'Flagged Notes: ${item.notes ?? 'Fuzzy match discrepancy detected'}',
                              style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                hintText: 'Enter verifier resolution notes...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _handleDecision(item.id, 'REJECTED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  icon: const Icon(Icons.cancel, size: 16),
                                  label: const Text('Reject Application'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _handleDecision(item.id, 'APPROVED'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: const Text('Approve Override'),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
